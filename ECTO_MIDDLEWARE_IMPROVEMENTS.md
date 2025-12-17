# EctoMiddleware Improvements for LiteFS Write Forwarding

**Date:** December 16, 2025  
**Issue:** Current `EctoMiddleware` design always executes `super()` call, even when before-middleware has already completed the operation remotely.

---

## Problem Analysis

### Current Behavior

When using `EctoMiddleware` for write forwarding in a LiteFS setup:

1. **Before middleware** runs on replica
2. Middleware forwards write to primary via `:erpc`
3. Primary executes the write and returns result
4. Middleware returns the **result** (e.g., `%Tag{id: 3, ...}`)
5. **`super()` is ALWAYS called** with that result
6. Attempts to insert an already-inserted record
7. Gets constraint error (duplicate ID)

### The Bug

From `deps/ecto_middleware/lib/ecto_middleware.ex` (lines 303-318):

```elixir
def insert(resource, opts) do
  resolution = Resolution.new!([resource, opts])
  resolution = Resolution.execute_before!(resolution)
  
  input = resolution.before_output  # ← Our middleware returns the RESULT
  
  case super(input, opts) do  # ← Tries to re-insert that result!
    {:ok, result} ->
      {:ok, Resolution.execute_after!(resolution, result).after_output}
    {:error, reason} ->
      {:error, reason}
  end
end
```

**What happens:**
1. Middleware forwards `Repo.insert(%Tag{label: "test"})` to primary
2. Primary inserts and returns `{:ok, %Tag{id: 3, label: "test"}}`
3. Our middleware unwraps and returns `%Tag{id: 3, ...}`
4. `super()` tries: `Repo.insert(%Tag{id: 3, ...}, [])`
5. SQLite error: "UNIQUE constraint failed: tags.id"

**Why it "works":**
- The constraint error prevents double-insert
- We already got the result from primary
- The error is caught and ignored (or causes the error we saw in testing)

**Why this is wrong:**
- Wasteful: Attempts unnecessary database operation
- Error-prone: Relies on constraint errors to prevent bad behavior
- Confusing: Logs show failed inserts that actually succeeded
- Fragile: May cause issues with transactions or complex operations

---

## Solution Options

### Option 1: Fork and Extend EctoMiddleware (Most Correct)

Modify `EctoMiddleware` to support early termination:

**Changes to `EctoMiddleware.Resolution`:**

```elixir
defmodule EctoMiddleware.Resolution do
  defstruct [
    :repo,
    :action,
    :args,
    :middleware,
    :entity,
    :before_middleware,
    :after_middleware,
    :before_input,
    :before_output,
    :after_input,
    :after_output,
    :halted,           # ← NEW: Signal to skip super()
    :halted_value      # ← NEW: Value to return when halted
  ]
  
  @doc "Halt middleware execution and return a value immediately"
  def halt(resolution, value) do
    %__MODULE__{resolution | halted: true, halted_value: value}
  end
end
```

**Changes to generated functions:**

```elixir
# In stub_ok_error_functions! macro
def insert(resource, opts) do
  resolution = Resolution.new!([resource, opts])
  resolution = Resolution.execute_before!(resolution)
  
  # ← NEW: Check if middleware halted
  if resolution.halted do
    resolution.halted_value
  else
    input = resolution.before_output
    
    case super(input, opts) do
      {:ok, result} ->
        {:ok, Resolution.execute_after!(resolution, result).after_output}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

**Our LiteFS middleware would use it:**

```elixir
defmodule Blog.Repo.Middleware.LiteFS do
  @impl EctoMiddleware
  def middleware(resource, %EctoMiddleware.Resolution{} = resolution) do
    case primary_status() do
      :primary ->
        # Execute locally
        resource
        
      {:replica, _hostname} ->
        # Forward to primary and halt
        result = forward_to_primary(resource, resolution)
        
        # Return special halt signal
        EctoMiddleware.Resolution.halt(resolution, result)
    end
  end
  
  defp forward_to_primary(resource, resolution) do
    # ... erpc forwarding logic ...
    :erpc.call(primary_node, repo, action, [resource, opts])
  end
end
```

**Pros:**
- ✅ Clean API: `Resolution.halt/2` is explicit and clear
- ✅ No wasted DB operations on replicas
- ✅ No reliance on constraint errors
- ✅ Can return any value type (`:ok`, `{:ok, result}`, etc.)
- ✅ Maintains middleware pipeline semantics

**Cons:**
- ❌ Requires forking `ecto_middleware`
- ❌ Need to maintain fork or contribute upstream
- ❌ Potential compatibility issues with future versions

---

### Option 2: Use Exception-Based Control Flow (Hacky)

Use exceptions to bypass `super()`:

```elixir
defmodule Blog.Repo.Middleware.LiteFS do
  # Special exception to signal "operation complete"
  defmodule ForwardedResult do
    defexception [:result]
    
    def message(%{result: result}), do: "Operation forwarded: #{inspect(result)}"
  end
  
  @impl EctoMiddleware
  def middleware(resource, resolution) do
    case primary_status() do
      :primary -> resource
      {:replica, _} ->
        result = forward_to_primary(resource, resolution)
        # Throw exception with result
        raise ForwardedResult, result: result
    end
  end
end
```

**Catch in Repo:**

```elixir
defmodule Blog.Repo do
  use Ecto.Repo, otp_app: :blog, adapter: Ecto.Adapters.SQLite3
  use EctoMiddleware
  
  # Override every function to catch our exception
  def insert(resource, opts \\ []) do
    super(resource, opts)
  rescue
    e in Blog.Repo.Middleware.LiteFS.ForwardedResult ->
      e.result
  end
  
  def update(resource, opts \\ []) do
    super(resource, opts)
  rescue
    e in Blog.Repo.Middleware.LiteFS.ForwardedResult ->
      e.result
  end
  
  # ... repeat for all write operations ...
end
```

**Pros:**
- ✅ Works with current `ecto_middleware`
- ✅ No forking required
- ✅ Clear signal that operation completed remotely

**Cons:**
- ❌ Exceptions for control flow (anti-pattern in Elixir)
- ❌ Must override every Repo function
- ❌ Lots of boilerplate
- ❌ Performance overhead from exception handling
- ❌ Confusing for debugging (exceptions in normal flow)

---

### Option 3: Return Original Resource and Accept DB Error (Current - Acceptable)

Keep current approach but fix the return value:

```elixir
defmodule Blog.Repo.Middleware.LiteFS do
  @impl EctoMiddleware
  def middleware(resource, resolution) do
    case primary_status() do
      :primary ->
        resource
        
      {:replica, _hostname} ->
        # Forward to primary
        _result = forward_to_primary(resource, resolution)
        
        # Return ORIGINAL resource (not result)
        # super() will execute on replica and get blocked by LiteFS
        # We swallow the error in after-middleware
        resource
    end
  end
end
```

**Add after-middleware to handle the error:**

```elixir
defmodule Blog.Repo.Middleware.LiteFS.ErrorHandler do
  @behaviour EctoMiddleware
  
  @impl EctoMiddleware
  def middleware(result, %EctoMiddleware.Resolution{} = resolution) do
    # If we're on a replica and got an error, it's expected (LiteFS blocked the write)
    # The actual result was already obtained by before-middleware via :erpc
    case {primary_status(), result} do
      {{:replica, _}, {:error, %Exqlite.Error{message: "disk I/O error"}}} ->
        # This error is expected - retrieve actual result from resolution metadata
        # We stored it during before-middleware
        get_forwarded_result(resolution)
        
      {_, result} ->
        # Primary or successful result - pass through
        result
    end
  end
end
```

**Pros:**
- ✅ Works with current `ecto_middleware`
- ✅ No forking required
- ✅ Explicit error handling

**Cons:**
- ❌ Wasted DB operation on every replica write
- ❌ Error logs for "failed" operations that actually succeeded
- ❌ Complex: Need to store/retrieve result across middleware
- ❌ Fragile: Relies on specific error message from LiteFS

---

### Option 4: Wrapper Functions (Simple but Limited)

Skip middleware entirely for replica writes:

```elixir
defmodule Blog.Repo do
  use Ecto.Repo, otp_app: :blog, adapter: Ecto.Adapters.SQLite3
  use EctoMiddleware
  
  # Don't use middleware for write forwarding
  def middleware(_action, _resource), do: [EctoMiddleware.Super]
  
  # Implement write forwarding at Repo level
  def insert(resource, opts \\ []) do
    case litefs_status() do
      :primary ->
        super(resource, opts)
        
      {:replica, primary_node} ->
        :erpc.call(primary_node, __MODULE__, :insert_on_primary, [resource, opts])
    end
  end
  
  # Separate function that ONLY runs on primary (never called via erpc on itself)
  def insert_on_primary(resource, opts) do
    super(resource, opts)
  end
  
  # Repeat for update, delete, etc...
end
```

**Pros:**
- ✅ No middleware complications
- ✅ Explicit control flow
- ✅ No wasted operations
- ✅ Clear separation of concerns

**Cons:**
- ❌ Bypasses middleware system entirely
- ❌ Can't use other middleware (logging, soft deletes, etc.)
- ❌ Lots of boilerplate for each operation
- ❌ Doesn't leverage `ecto_middleware` at all

---

### Option 5: Store Result in Resolution and Use After-Middleware (Clever)

Use the `Resolution` struct to smuggle the result:

```elixir
defmodule Blog.Repo.Middleware.LiteFS do
  @impl EctoMiddleware
  def middleware(resource, resolution) do
    case primary_status() do
      :primary ->
        resource
        
      {:replica, _} ->
        result = forward_to_primary(resource, resolution)
        
        # Store result in resolution metadata (ab)using before_output
        # Since super() won't actually succeed, we need to preserve this
        resolution = put_in(resolution.__struct__, :litefs_result, result)
        
        # Return original resource (will fail on replica)
        resource
    end
  end
end

defmodule Blog.Repo.Middleware.LiteFS.AfterForward do
  @behaviour EctoMiddleware
  
  @impl EctoMiddleware
  def middleware(result, resolution) do
    # Check if we stored a forwarded result
    case Map.get(resolution, :litefs_result) do
      nil ->
        # Normal flow
        result
        
      forwarded_result ->
        # We forwarded - ignore local error and return forwarded result
        forwarded_result
    end
  end
end
```

**In Repo:**

```elixir
def middleware(action, _resource) when action in @write_actions do
  [
    Blog.Repo.Middleware.LiteFS,
    EctoMiddleware.Super,
    Blog.Repo.Middleware.LiteFS.AfterForward
  ]
end
```

**Pros:**
- ✅ Works with current `ecto_middleware`
- ✅ No forking required
- ✅ Gracefully handles the local error
- ✅ After-middleware can fix the result

**Cons:**
- ❌ Wasted DB operation attempt
- ❌ Abuses `Resolution` struct (not designed for custom fields)
- ❌ Error logs for expected failures
- ❌ Hacky: storing result in wrong place

---

## Recommendation

**Best short-term solution: Option 5** (Store in Resolution + After-Middleware)

This works with the current `ecto_middleware` and is relatively clean, though it wastes a DB operation.

**Best long-term solution: Option 1** (Fork and add halt support)

Submit PR to `ecto_middleware` to add `Resolution.halt/2` functionality. This is the most correct approach and benefits the entire Elixir community.

**Interim approach:**

1. Implement Option 5 now (works immediately)
2. Create fork of `ecto_middleware` with Option 1
3. Submit PR upstream
4. If accepted, remove Option 5 and use halt mechanism
5. If rejected, maintain fork or stick with Option 5

---

## Implementation Priority

1. **Document current behavior** ✅ (this file)
2. **Implement Option 5** - Quick win, works with current library
3. **Test thoroughly** - Ensure no edge cases
4. **Create fork with Option 1** - Better long-term solution
5. **Submit upstream PR** - Benefit community
6. **Monitor for acceptance** - Switch if accepted

---

## Open Questions

1. Does the wasted DB operation on replicas cause any harm beyond logs?
2. Can we silence the expected "disk I/O error" logs?
3. Should we cache the primary node discovery?
4. What happens during primary failover?
5. How do we test this behavior in CI?

---

## References

- EctoMiddleware: https://hexdocs.pm/ecto_middleware
- EctoMiddleware Source: `/deps/ecto_middleware/lib/`
- Our Implementation: `/apps/blog/lib/blog/repo/middleware/litefs.ex`
- LiteFS Docs: https://fly.io/docs/litefs/
