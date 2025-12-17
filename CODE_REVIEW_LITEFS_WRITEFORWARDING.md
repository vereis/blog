# Code Review: LiteFS Write Forwarding with EctoMiddleware

**Review Date:** December 16, 2025  
**Reviewer:** Code Review Agent  
**Files Reviewed:**
- `apps/blog/lib/blog/repo.ex`
- `apps/blog/lib/blog/repo/middleware/litefs.ex`
- `apps/blog/mix.exs`
- `fly.toml`
- `litefs.yml`
- `DEPLOYMENT_ANALYSIS.md`
- `LITEFS_WRITEFORWARDING.md`

---

## 1. Overall Assessment

**Rating: 🟡 MAJOR ISSUES**

The implementation demonstrates a creative solution to the LiteFS WebSocket limitation, but contains several **critical bugs**, **missing edge case handling**, and **incomplete Ecto operation coverage** that could cause production failures. The architecture is sound, but the implementation needs significant hardening before production deployment.

**Summary:**
- ✅ Good architectural decision to use `:erpc` over HTTP forwarding
- ✅ Clean middleware pattern using EctoMiddleware
- ✅ Excellent documentation
- 🔴 Critical bugs in error handling and result unwrapping
- 🔴 Missing coverage for `insert_all`, `update_all`, `delete_all`, `transaction`, `Multi`
- 🟡 Race conditions in primary node discovery
- 🟡 No timeout configuration for `:erpc` calls
- 🟡 Missing retry logic for transient failures
- 🔵 No tests for the middleware

---

## 2. Issues Found

### 🔴 CRITICAL Issues (Must Fix)

#### C1: Incorrect Result Unwrapping Breaks Ecto Semantics

**Location:** `apps/blog/lib/blog/repo/middleware/litefs.ex:111-125`

**Problem:** The middleware incorrectly unwraps `{:ok, result}` tuples, breaking Ecto's return type contract.

```elixir
# Current code (BROKEN)
case :erpc.call(primary_node, repo, action, [resource, opts]) do
  {:ok, result} ->
    # For operations that return {:ok, result}, return just the result
    # since the middleware expects the unwrapped value
    result  # ❌ WRONG - returns unwrapped value

  {:error, _reason} = error ->
    raise "Write operation failed on primary: #{inspect(error)}"  # ❌ WRONG

  result ->
    result
end
```

**Why it's wrong:**

1. **EctoMiddleware expects the raw return value**, not unwrapped. Looking at `EctoMiddleware.stub_ok_error_functions!/0`:
   ```elixir
   case super(...) do
     {:ok, result} ->
       {:ok, Resolution.execute_after!(resolution, result).after_output}
     {:error, reason} ->
       {:error, reason}
   end
   ```
   The middleware framework handles the `{:ok, result}` wrapping. The before-middleware should return the **resource** (changeset/struct), not the operation result.

2. **The middleware runs BEFORE the Repo call**, not instead of it. Looking at the middleware chain:
   ```elixir
   [Blog.Repo.Middleware.LiteFS, EctoMiddleware.Super]
   ```
   `EctoMiddleware.Super` is what actually calls the Repo. The LiteFS middleware should either:
   - Return the resource unchanged (pass-through to local execution)
   - Short-circuit by returning a modified resource that prevents execution

3. **The current implementation tries to execute the operation AND return the result**, which means:
   - On primary: Operation runs twice (once in middleware, once in Super)
   - On replica: Operation runs on primary, then Super tries to run it locally (fails with SQLITE_READONLY)

**Impact:** 
- Double writes on primary
- SQLITE_READONLY errors on replicas
- Broken return types causing downstream failures

**Fix:**

The middleware needs to be restructured. Since EctoMiddleware doesn't support short-circuiting (the Super middleware always runs), we need a different approach:

```elixir
defmodule Blog.Repo.Middleware.LiteFS do
  @behaviour EctoMiddleware
  @primary_file "/litefs/.primary"

  @impl EctoMiddleware
  def middleware(resource, %EctoMiddleware.Resolution{} = resolution) do
    case primary_status() do
      :primary ->
        # We're the primary - let Super execute locally
        resource

      {:replica, _primary_hostname} ->
        # We're a replica - we need to forward to primary
        # BUT: EctoMiddleware.Super will still try to execute locally after us
        # This is a fundamental limitation - we need to either:
        # 1. Modify the resource to be a no-op (not possible for all operations)
        # 2. Use a different pattern (wrap Repo functions directly)
        # 3. Accept that this middleware pattern doesn't work for write forwarding
        
        # For now, raise to prevent silent failures
        raise """
        Write operation attempted on replica node.
        
        The current EctoMiddleware pattern cannot properly forward writes because
        EctoMiddleware.Super always executes after before-middleware.
        
        Consider using a Repo wrapper module instead of middleware.
        """

      {:error, :not_litefs} ->
        # Not running in LiteFS environment (dev/test) - execute locally
        resource
    end
  end
end
```

**Alternative Fix (Recommended):** Use a wrapper module pattern instead of middleware:

```elixir
defmodule Blog.WriteForwardingRepo do
  @primary_file "/litefs/.primary"
  
  @write_actions [:insert, :insert!, :update, :update!, :delete, :delete!, 
                  :insert_or_update, :insert_or_update!, :insert_all, 
                  :update_all, :delete_all]
  
  for action <- @write_actions do
    def unquote(action)(resource, opts \\ []) do
      case primary_status() do
        :primary ->
          apply(Blog.Repo, unquote(action), [resource, opts])
          
        {:replica, _} ->
          primary_node = find_primary_node!()
          :erpc.call(primary_node, Blog.Repo, unquote(action), [resource, opts], 30_000)
          
        {:error, :not_litefs} ->
          apply(Blog.Repo, unquote(action), [resource, opts])
      end
    end
  end
  
  # Delegate all read operations to Blog.Repo
  defdelegate all(queryable, opts \\ []), to: Blog.Repo
  defdelegate get(queryable, id, opts \\ []), to: Blog.Repo
  # ... etc
end
```

---

#### C2: Missing Coverage for Bulk Operations

**Location:** `apps/blog/lib/blog/repo.ex:8`

**Problem:** The `@write_actions` list is incomplete:

```elixir
@write_actions [:insert, :insert!, :update, :update!, :delete, :delete!, 
                :insert_or_update, :insert_or_update!]
```

**Missing operations:**
- `insert_all/3` - Bulk inserts
- `update_all/3` - Bulk updates  
- `delete_all/2` - Bulk deletes
- `transaction/2` - Transactions containing writes
- `Ecto.Multi` operations via `transaction/2`

**Impact:** Any code using these operations will execute locally on replicas, causing `SQLITE_READONLY` errors.

**Fix:**

```elixir
@write_actions [
  :insert, :insert!, 
  :update, :update!, 
  :delete, :delete!, 
  :insert_or_update, :insert_or_update!,
  :insert_all,
  :update_all,
  :delete_all
]
```

**Note:** `transaction/2` is more complex because:
1. It takes a function, not a resource
2. The function may contain reads AND writes
3. EctoMiddleware doesn't intercept `transaction/2`

For transactions, you need a different approach - see C3.

---

#### C3: Transactions Not Handled

**Location:** Not implemented

**Problem:** `Repo.transaction/2` is not intercepted by EctoMiddleware (it's not in the overridable functions list). Any transaction containing writes will fail on replicas.

**Example that will fail:**

```elixir
Blog.Repo.transaction(fn ->
  post = Blog.Repo.insert!(%Post{title: "Hello"})
  Blog.Repo.insert!(%Comment{post_id: post.id, body: "World"})
end)
```

**Impact:** All transactional code fails on replicas with `SQLITE_READONLY`.

**Fix Options:**

1. **Wrap transaction at application level:**
   ```elixir
   defmodule Blog.WriteForwardingRepo do
     def transaction(fun_or_multi, opts \\ []) do
       case primary_status() do
         :primary ->
           Blog.Repo.transaction(fun_or_multi, opts)
         {:replica, _} ->
           primary_node = find_primary_node!()
           # WARNING: This won't work because `fun` captures local context
           # and closures can't be serialized across nodes
           raise "Transactions must be executed on primary node"
         {:error, :not_litefs} ->
           Blog.Repo.transaction(fun_or_multi, opts)
       end
     end
   end
   ```

2. **Use named functions instead of closures:**
   ```elixir
   # Instead of:
   Repo.transaction(fn -> ... end)
   
   # Use:
   def create_post_with_comment(post_params, comment_params) do
     # This function can be called via :erpc
   end
   
   :erpc.call(primary_node, MyModule, :create_post_with_comment, [params1, params2])
   ```

3. **Document the limitation clearly** and require all writes to go through specific service modules that handle forwarding.

---

#### C4: No Error Handling for `:erpc` Failures

**Location:** `apps/blog/lib/blog/repo/middleware/litefs.ex:126-140`

**Problem:** The error handling only catches `ErlangError`, missing many failure modes:

```elixir
rescue
  error in ErlangError ->
    reraise RuntimeError, "...", __STACKTRACE__
```

**Missing error cases:**
- `:erpc.call/4` can return `{:EXIT, reason}` for process crashes
- `:erpc.call/4` can return `{:throw, reason}` for thrown values
- `:erpc.call/4` raises `ErlangError` with different reasons:
  - `{:erpc, :noconnection}` - Node unreachable
  - `{:erpc, :timeout}` - Call timed out
  - `{:erpc, :notsup}` - Remote node doesn't support erpc
  - `{:exception, reason, stacktrace}` - Remote exception

**Impact:** Unclear error messages, potential silent failures, no ability to retry transient errors.

**Fix:**

```elixir
defp forward_to_primary(resource, resolution, _primary_short_hostname) do
  %{repo: repo, action: action, args: args} = resolution
  
  primary_node = find_primary_node!()
  opts = extract_opts(args)
  
  try do
    case :erpc.call(primary_node, repo, action, [resource, opts], @erpc_timeout) do
      {:badrpc, reason} ->
        raise WriteForwardingError, 
          message: "RPC to primary failed",
          reason: reason,
          node: primary_node,
          action: action
          
      result ->
        result
    end
  catch
    :exit, {:erpc, :noconnection} ->
      raise WriteForwardingError,
        message: "Primary node unreachable",
        reason: :noconnection,
        node: primary_node,
        action: action
        
    :exit, {:erpc, :timeout} ->
      raise WriteForwardingError,
        message: "Write forwarding timed out after #{@erpc_timeout}ms",
        reason: :timeout,
        node: primary_node,
        action: action
        
    :exit, {:exception, exception, stacktrace} ->
      reraise exception, stacktrace
      
    :exit, reason ->
      raise WriteForwardingError,
        message: "Write forwarding failed",
        reason: reason,
        node: primary_node,
        action: action
  end
end
```

---

### 🟡 WARNING Issues (Should Fix)

#### W1: Race Condition in Primary Node Discovery

**Location:** `apps/blog/lib/blog/repo/middleware/litefs.ex:84-94`

**Problem:** The primary node discovery iterates through all nodes and checks each one via `:erpc`. This has several issues:

```elixir
primary_node =
  Enum.find([Node.self() | Node.list()], fn node ->
    if :erpc.call(node, File, :exists?, [@primary_file]) do
      false
    else
      true
    end
  end)
```

**Issues:**

1. **Race condition:** Primary can change between discovery and write execution
2. **Performance:** N `:erpc` calls for N nodes on every write
3. **No caching:** Same discovery runs for every single write operation
4. **Inverted logic bug:** The `if` returns `false` when file exists, but the comment says "No .primary file = this is the primary" - the logic is correct but confusing

**Impact:** 
- Slow writes (multiple network round-trips)
- Potential writes to wrong node during failover
- Unnecessary load on all cluster nodes

**Fix:**

```elixir
defmodule Blog.Repo.Middleware.LiteFS do
  use GenServer
  
  @primary_file "/litefs/.primary"
  @cache_ttl_ms 5_000  # Cache primary for 5 seconds
  
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end
  
  def get_primary_node do
    GenServer.call(__MODULE__, :get_primary)
  end
  
  @impl GenServer
  def init(_) do
    {:ok, %{primary_node: nil, cached_at: nil}}
  end
  
  @impl GenServer
  def handle_call(:get_primary, _from, state) do
    now = System.monotonic_time(:millisecond)
    
    if state.primary_node && state.cached_at && 
       now - state.cached_at < @cache_ttl_ms do
      {:reply, state.primary_node, state}
    else
      primary = discover_primary_node()
      {:reply, primary, %{primary_node: primary, cached_at: now}}
    end
  end
  
  defp discover_primary_node do
    # Check self first (most common case - we might be primary)
    if !File.exists?(@primary_file) do
      Node.self()
    else
      # We're a replica, find the primary
      Enum.find(Node.list(), fn node ->
        try do
          !:erpc.call(node, File, :exists?, [@primary_file], 5_000)
        catch
          _, _ -> false
        end
      end)
    end
  end
end
```

---

#### W2: No Timeout Configuration for `:erpc.call`

**Location:** `apps/blog/lib/blog/repo/middleware/litefs.ex:111`

**Problem:** `:erpc.call/4` uses the default timeout of 5000ms, which may not be appropriate:

```elixir
:erpc.call(primary_node, repo, action, [resource, opts])
```

**Issues:**
- Default 5s timeout may be too short for large inserts
- Default 5s timeout may be too long for simple operations
- No way to configure per-operation or globally

**Impact:** Timeouts on legitimate operations, or unnecessarily long waits on failures.

**Fix:**

```elixir
@default_erpc_timeout 30_000  # 30 seconds

defp forward_to_primary(resource, resolution, _primary_short_hostname) do
  %{repo: repo, action: action, args: args} = resolution
  
  opts = extract_opts(args)
  timeout = Keyword.get(opts, :erpc_timeout, @default_erpc_timeout)
  
  primary_node = find_primary_node!()
  
  :erpc.call(primary_node, repo, action, [resource, opts], timeout)
end
```

---

#### W3: Opts Extraction is Incomplete

**Location:** `apps/blog/lib/blog/repo/middleware/litefs.ex:100-106`

**Problem:** The opts extraction doesn't handle all Ecto function signatures:

```elixir
opts =
  case args do
    [_resource, opts] when is_list(opts) -> opts
    [_resource, _id, opts] when is_list(opts) -> opts
    _ -> []
  end
```

**Missing patterns:**
- `insert_all(schema, entries, opts)` - 3 args where second is entries list
- `update_all(queryable, updates, opts)` - 3 args where second is updates
- `delete_all(queryable, opts)` - 2 args but queryable isn't a struct

**Impact:** Options like `:returning`, `:on_conflict`, `:prefix` may be lost.

**Fix:**

```elixir
defp extract_opts(args) do
  case args do
    # insert/update/delete with opts
    [_resource, opts] when is_list(opts) -> opts
    
    # get/get_by with id and opts
    [_queryable, _id, opts] when is_list(opts) -> opts
    
    # insert_all(schema, entries, opts)
    [_schema, entries, opts] when is_list(entries) and is_list(opts) -> opts
    
    # update_all(queryable, updates, opts)
    [_queryable, updates, opts] when is_list(updates) and is_list(opts) -> opts
    
    # No opts provided
    _ -> []
  end
end
```

---

#### W4: Primary File Read on Every Operation

**Location:** `apps/blog/lib/blog/repo/middleware/litefs.ex:58-72`

**Problem:** `File.read/1` is called on every write operation:

```elixir
defp primary_status do
  case File.read(@primary_file) do
    {:ok, hostname} -> {:replica, String.trim(hostname)}
    {:error, :enoent} -> :primary
    {:error, _reason} -> {:error, :not_litefs}
  end
end
```

**Issues:**
- File I/O on every write (even if cached by OS)
- No caching of primary status
- Primary status can change, but checking every operation is excessive

**Impact:** Unnecessary overhead, though likely minimal due to OS caching.

**Fix:** Cache the status with a short TTL:

```elixir
defmodule Blog.Repo.Middleware.LiteFS.PrimaryStatus do
  use Agent
  
  @cache_ttl_ms 1_000  # 1 second
  
  def start_link(_) do
    Agent.start_link(fn -> {nil, 0} end, name: __MODULE__)
  end
  
  def get do
    Agent.get_and_update(__MODULE__, fn {cached_status, cached_at} ->
      now = System.monotonic_time(:millisecond)
      
      if cached_status && now - cached_at < @cache_ttl_ms do
        {cached_status, {cached_status, cached_at}}
      else
        status = read_primary_status()
        {status, {status, now}}
      end
    end)
  end
  
  defp read_primary_status do
    case File.read("/litefs/.primary") do
      {:ok, hostname} -> {:replica, String.trim(hostname)}
      {:error, :enoent} -> :primary
      {:error, _reason} -> {:error, :not_litefs}
    end
  end
end
```

---

#### W5: No Retry Logic for Transient Failures

**Location:** `apps/blog/lib/blog/repo/middleware/litefs.ex`

**Problem:** Network issues, temporary node unavailability, and other transient failures cause immediate failure with no retry.

**Impact:** Unnecessary failures during brief network hiccups or node restarts.

**Fix:**

```elixir
@max_retries 3
@retry_delay_ms 100

defp forward_to_primary(resource, resolution, primary_hostname, retries \\ 0) do
  try do
    do_forward(resource, resolution)
  catch
    :exit, {:erpc, reason} when reason in [:noconnection, :timeout] and retries < @max_retries ->
      Process.sleep(@retry_delay_ms * (retries + 1))  # Exponential backoff
      
      # Invalidate cached primary in case of failover
      invalidate_primary_cache()
      
      forward_to_primary(resource, resolution, primary_hostname, retries + 1)
  end
end
```

---

#### W6: Changeset Serialization May Fail

**Location:** `apps/blog/lib/blog/repo/middleware/litefs.ex:111`

**Problem:** Changesets containing anonymous functions (in validations, constraints) cannot be serialized across nodes:

```elixir
:erpc.call(primary_node, repo, action, [resource, opts])
```

**Example that will fail:**

```elixir
%Post{}
|> Ecto.Changeset.cast(params, [:title])
|> Ecto.Changeset.validate_change(:title, fn :title, value ->
  if String.contains?(value, "bad"), do: [title: "invalid"], else: []
end)
|> Blog.Repo.insert()  # Will fail - anonymous function can't be serialized
```

**Impact:** Runtime errors when changesets contain closures.

**Fix:** Document the limitation and recommend using named validation functions:

```elixir
# In changeset module
def validate_title(changeset) do
  validate_change(changeset, :title, &do_validate_title/2)
end

defp do_validate_title(:title, value) do
  if String.contains?(value, "bad"), do: [title: "invalid"], else: []
end
```

---

#### W7: No Monitoring or Metrics

**Location:** Not implemented

**Problem:** No visibility into:
- Write forwarding latency
- Forwarding success/failure rates
- Primary node discovery time
- Retry counts

**Impact:** Difficult to debug production issues, no alerting on degradation.

**Fix:**

```elixir
defp forward_to_primary(resource, resolution, primary_hostname) do
  start_time = System.monotonic_time()
  
  try do
    result = do_forward(resource, resolution)
    
    :telemetry.execute(
      [:blog, :repo, :write_forwarding, :success],
      %{duration: System.monotonic_time() - start_time},
      %{action: resolution.action, primary_node: primary_hostname}
    )
    
    result
  catch
    kind, reason ->
      :telemetry.execute(
        [:blog, :repo, :write_forwarding, :failure],
        %{duration: System.monotonic_time() - start_time},
        %{action: resolution.action, error: reason, kind: kind}
      )
      
      :erlang.raise(kind, reason, __STACKTRACE__)
  end
end
```

---

### 🔵 SUGGESTIONS (Nice to Have)

#### S1: Add Typespec for Middleware Function

**Location:** `apps/blog/lib/blog/repo/middleware/litefs.ex:41`

```elixir
@impl EctoMiddleware
@spec middleware(EctoMiddleware.resource(), EctoMiddleware.Resolution.t()) :: EctoMiddleware.resource()
def middleware(resource, %EctoMiddleware.Resolution{} = resolution) do
```

---

#### S2: Use Module Attribute for Primary File Path

**Location:** `apps/blog/lib/blog/repo/middleware/litefs.ex:38`

Already done correctly:
```elixir
@primary_file "/litefs/.primary"
```

But consider making it configurable:

```elixir
@primary_file Application.compile_env(:blog, :litefs_primary_file, "/litefs/.primary")
```

---

#### S3: Add Debug Logging

```elixir
require Logger

defp forward_to_primary(resource, resolution, primary_hostname) do
  Logger.debug(fn ->
    "Forwarding #{resolution.action} to primary node #{primary_hostname}"
  end)
  
  # ... rest of implementation
end
```

---

#### S4: Consider Circuit Breaker Pattern

For production resilience, consider implementing a circuit breaker:

```elixir
defmodule Blog.Repo.Middleware.LiteFS.CircuitBreaker do
  use GenServer
  
  @failure_threshold 5
  @reset_timeout_ms 30_000
  
  # ... implementation
end
```

---

## 3. Missing Tests

The middleware has **zero tests**. The following tests should be added:

### Unit Tests for `Blog.Repo.Middleware.LiteFS`

```elixir
# test/blog/repo/middleware/litefs_test.exs

defmodule Blog.Repo.Middleware.LiteFSTest do
  use Blog.DataCase, async: false  # Can't be async due to file system mocking
  
  alias Blog.Repo.Middleware.LiteFS
  alias EctoMiddleware.Resolution
  
  describe "primary_status/0" do
    test "returns :primary when /litefs/.primary does not exist" do
      # Mock File.read to return {:error, :enoent}
      # Assert primary_status() == :primary
    end
    
    test "returns {:replica, hostname} when /litefs/.primary exists" do
      # Mock File.read to return {:ok, "primary-host\n"}
      # Assert primary_status() == {:replica, "primary-host"}
    end
    
    test "returns {:error, :not_litefs} for other file errors" do
      # Mock File.read to return {:error, :eacces}
      # Assert primary_status() == {:error, :not_litefs}
    end
  end
  
  describe "middleware/2 on primary" do
    setup do
      # Mock as primary
      :ok
    end
    
    test "passes through resource unchanged for insert" do
      changeset = %Ecto.Changeset{}
      resolution = %Resolution{action: :insert, args: [changeset, []]}
      
      assert LiteFS.middleware(changeset, resolution) == changeset
    end
  end
  
  describe "middleware/2 on replica" do
    setup do
      # Mock as replica
      # Start a mock "primary" node
      :ok
    end
    
    test "forwards insert to primary node" do
      # This requires a multi-node test setup
    end
    
    test "raises when primary node not found" do
      # Mock Node.list() to return []
      # Assert raises with appropriate message
    end
    
    test "handles :erpc timeout" do
      # Mock :erpc.call to raise timeout
    end
    
    test "handles :erpc noconnection" do
      # Mock :erpc.call to raise noconnection
    end
  end
  
  describe "find_primary_node/0" do
    test "returns self when self is primary" do
      # Mock File.exists? to return false for self
    end
    
    test "finds primary among connected nodes" do
      # Mock multiple nodes, one without .primary file
    end
    
    test "raises when no primary found" do
      # Mock all nodes to have .primary file
    end
  end
end
```

### Integration Tests

```elixir
# test/blog/repo/middleware/litefs_integration_test.exs

defmodule Blog.Repo.Middleware.LiteFSIntegrationTest do
  use Blog.DataCase, async: false
  
  @moduletag :integration
  @moduletag :litefs
  
  # These tests require a multi-node setup
  # Run with: mix test --only litefs
  
  describe "write forwarding" do
    @tag :skip  # Skip unless running in LiteFS environment
    test "insert on replica forwards to primary" do
      # Create a tag on replica
      # Verify it exists on primary
      # Verify it replicates back to replica
    end
    
    @tag :skip
    test "update on replica forwards to primary" do
      # Similar test for update
    end
    
    @tag :skip
    test "delete on replica forwards to primary" do
      # Similar test for delete
    end
  end
  
  describe "error scenarios" do
    @tag :skip
    test "handles primary node failure gracefully" do
      # Kill primary, verify error handling
    end
    
    @tag :skip
    test "handles network partition" do
      # Simulate network partition
    end
  end
end
```

### Property-Based Tests

```elixir
# test/blog/repo/middleware/litefs_property_test.exs

defmodule Blog.Repo.Middleware.LiteFSPropertyTest do
  use ExUnit.Case
  use ExUnitProperties
  
  describe "opts extraction" do
    property "extracts opts from any valid args pattern" do
      check all args <- args_generator() do
        opts = LiteFS.extract_opts(args)
        assert is_list(opts)
      end
    end
  end
end
```

---

## 4. Documentation Improvements

### LITEFS_WRITEFORWARDING.md

**Issues:**

1. **Line 131:** The code example shows calling `:erpc.call` directly in middleware, but this doesn't work with EctoMiddleware's execution model.

2. **Missing:** No documentation of the fundamental limitation that EctoMiddleware.Super always runs after before-middleware.

3. **Missing:** No documentation of transaction limitations.

4. **Missing:** No documentation of changeset serialization limitations.

**Recommended additions:**

```markdown
## Known Limitations

### 1. Transactions Cannot Be Forwarded

Ecto transactions (`Repo.transaction/2`) cannot be automatically forwarded because:
- The transaction function is a closure that captures local state
- Closures cannot be serialized across Erlang nodes
- EctoMiddleware does not intercept `transaction/2`

**Workaround:** Use service modules with named functions:

\`\`\`elixir
# Instead of:
Repo.transaction(fn ->
  post = Repo.insert!(%Post{})
  Repo.insert!(%Comment{post_id: post.id})
end)

# Use:
defmodule Blog.Posts do
  def create_with_comment(post_params, comment_params) do
    Repo.transaction(fn ->
      post = Repo.insert!(%Post{} |> Post.changeset(post_params))
      Repo.insert!(%Comment{post_id: post.id} |> Comment.changeset(comment_params))
    end)
  end
end

# Then forward the service call:
:erpc.call(primary_node, Blog.Posts, :create_with_comment, [post_params, comment_params])
\`\`\`

### 2. Changesets with Anonymous Functions

Changesets containing anonymous functions in validations cannot be serialized:

\`\`\`elixir
# This will FAIL when forwarded:
changeset
|> validate_change(:field, fn _, value -> ... end)
|> Repo.insert()

# Use named functions instead:
changeset
|> validate_change(:field, &MyValidator.validate_field/2)
|> Repo.insert()
\`\`\`

### 3. Bulk Operations

`insert_all`, `update_all`, and `delete_all` require special handling because
their argument patterns differ from single-record operations.
```

### DEPLOYMENT_ANALYSIS.md

**Issues:**

1. **Line 1199-1305:** The "Ecto Middleware Plan" section describes an implementation that doesn't match the actual code.

2. **Outdated:** References to "To Be Implemented" when implementation exists.

**Recommended:** Update to reflect actual implementation and its limitations.

---

## 5. Risk Assessment for Production Deployment

### High Risk Items

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Double writes on primary | High | High | Fix C1 - restructure middleware |
| SQLITE_READONLY on replica | High | High | Fix C1 - restructure middleware |
| Transaction failures | Medium | High | Document limitation, use service modules |
| Changeset serialization failures | Medium | Medium | Document limitation, use named functions |
| Primary discovery race condition | Low | Medium | Implement caching with TTL |

### Deployment Checklist

Before deploying to production:

- [ ] Fix C1: Restructure middleware or use wrapper pattern
- [ ] Fix C2: Add missing bulk operations
- [ ] Fix C3: Document transaction limitations
- [ ] Fix C4: Improve error handling
- [ ] Add W7: Telemetry/monitoring
- [ ] Add comprehensive tests
- [ ] Update documentation
- [ ] Test in staging with multi-region setup
- [ ] Set up alerting for write forwarding failures
- [ ] Create runbook for primary failover scenarios

### Recommended Deployment Strategy

1. **Phase 1:** Fix critical bugs (C1-C4), deploy to single region
2. **Phase 2:** Add monitoring (W7), observe in production
3. **Phase 3:** Add caching and retry logic (W1, W5)
4. **Phase 4:** Scale to multi-region with careful monitoring

---

## 6. Summary

The LiteFS write forwarding implementation is a creative solution to a real problem (WebSocket incompatibility with LiteFS proxy), but the current implementation has fundamental issues with how it integrates with EctoMiddleware.

**Key Takeaways:**

1. **The middleware pattern may not be suitable** for write forwarding because `EctoMiddleware.Super` always executes after before-middleware, meaning the local Repo call will always run.

2. **A wrapper module pattern** would be more appropriate for this use case.

3. **Transactions and bulk operations** need special handling that isn't currently implemented.

4. **Testing is completely absent** - this is a significant risk for production.

5. **The documentation is excellent** but needs updates to reflect actual limitations.

**Recommendation:** Before production deployment, either:
- Restructure to use a wrapper module pattern instead of middleware, OR
- Verify that the current implementation actually works (it may not due to C1)

The architecture is sound, but the implementation needs significant work.
