# LiteFS Middleware: Proof of Concept for Preventing Duplicate Operations

**Goal:** Prevent `super()` from executing a duplicate database operation after write has been forwarded to primary.

**Approach:** Use after-middleware to intercept and replace the failed local result with the successful remote result.

---

## Implementation (Option 5: Store Result in Process Dictionary)

Since we can't modify the `Resolution` struct (it's a defined struct), we'll use the process dictionary to smuggle the result between before and after middleware.

### Step 1: Modified LiteFS Before-Middleware

```elixir
defmodule Blog.Repo.Middleware.LiteFS do
  @moduledoc """
  Middleware that forwards write operations to the primary LiteFS node using :erpc.
  
  For replicas:
  1. Forwards operation to primary
  2. Stores result in process dictionary
  3. Returns original resource (which will fail locally)
  4. After-middleware retrieves stored result and returns it
  """
  
  @behaviour EctoMiddleware
  
  @primary_file "/litefs/.primary"
  @result_key :litefs_forwarded_result
  
  @impl EctoMiddleware
  def middleware(resource, %EctoMiddleware.Resolution{} = resolution) do
    case primary_status() do
      :primary ->
        # We're the primary - execute locally
        # Clear any stale forwarded result
        Process.delete(@result_key)
        resource
        
      {:replica, primary_hostname} ->
        # We're a replica - forward to primary
        result = forward_to_primary(resource, resolution, primary_hostname)
        
        # Store result in process dictionary for after-middleware
        Process.put(@result_key, result)
        
        # Return original resource
        # super() will attempt to execute and fail with "disk I/O error"
        resource
        
      {:error, :not_litefs} ->
        # Not running in LiteFS environment (dev/test)
        Process.delete(@result_key)
        resource
    end
  end
  
  # ... rest of implementation (primary_status, forward_to_primary) unchanged ...
end
```

### Step 2: New After-Middleware to Handle Result

```elixir
defmodule Blog.Repo.Middleware.LiteFS.ResultHandler do
  @moduledoc """
  After-middleware that handles the result of write operations.
  
  If a result was forwarded to primary (stored in process dictionary),
  this middleware replaces the failed local result with the successful remote result.
  """
  
  @behaviour EctoMiddleware
  
  @result_key :litefs_forwarded_result
  
  @impl EctoMiddleware
  def middleware(result, %EctoMiddleware.Resolution{} = _resolution) do
    case Process.get(@result_key) do
      nil ->
        # No forwarded result - normal local execution
        result
        
      forwarded_result ->
        # We forwarded to primary - ignore local error and return remote result
        Process.delete(@result_key)
        forwarded_result
    end
  end
end
```

### Step 3: Configure Middleware Pipeline

```elixir
defmodule Blog.Repo do
  use Ecto.Repo, otp_app: :blog, adapter: Ecto.Adapters.SQLite3
  use EctoMiddleware
  
  @write_actions [
    :insert, :insert!,
    :update, :update!,
    :delete, :delete!,
    :insert_or_update, :insert_or_update!
  ]
  
  @impl EctoMiddleware
  def middleware(action, _resource) when action in @write_actions do
    [
      Blog.Repo.Middleware.LiteFS,        # Before: Forward if replica
      EctoMiddleware.Super,                # Execute (will fail on replica)
      Blog.Repo.Middleware.LiteFS.ResultHandler  # After: Replace result if forwarded
    ]
  end
  
  def middleware(_action, _resource) do
    # Read operations don't need forwarding
    [EctoMiddleware.Super]
  end
end
```

---

## How It Works

### On Primary Node

```
1. LiteFS middleware: Detects primary, clears process dict, returns resource
2. Super: Executes insert locally → {:ok, %Tag{id: 3, ...}}
3. ResultHandler: No forwarded result, returns result as-is
4. Final result: {:ok, %Tag{id: 3, ...}}
```

### On Replica Node

```
1. LiteFS middleware:
   - Detects replica
   - Forwards to primary via :erpc → {:ok, %Tag{id: 3, ...}}
   - Stores result in process dict
   - Returns original resource %Tag{label: "test"}
   
2. Super: Attempts insert locally
   - Exqlite tries to write to /litefs/blog.db
   - LiteFS blocks: {:error, %Exqlite.Error{message: "disk I/O error"}}
   
3. ResultHandler:
   - Finds forwarded result in process dict
   - Ignores the error from step 2
   - Returns: {:ok, %Tag{id: 3, ...}}
   
4. Final result: {:ok, %Tag{id: 3, ...}}
```

---

## Testing the Implementation

### Test 1: Write on Primary

```elixir
# On primary (LHR)
iex> Blog.Repo.insert(%Blog.Tags.Tag{label: "primary-test"})
{:ok, %Blog.Tags.Tag{id: 25, label: "primary-test", ...}}

# Process dict should be empty
iex> Process.get(:litefs_forwarded_result)
nil
```

### Test 2: Write on Replica

```elixir
# On replica (IAD)
iex> Blog.Repo.insert(%Blog.Tags.Tag{label: "replica-test"})
{:ok, %Blog.Tags.Tag{id: 26, label: "replica-test", ...}}

# Process dict should be cleaned up
iex> Process.get(:litefs_forwarded_result)
nil
```

### Test 3: Verify No Duplicate Inserts

```bash
# On primary
$ sqlite3 /litefs/blog.db "SELECT COUNT(*) FROM tags WHERE label = 'replica-test'"
1  # Should be exactly 1

# On replica
$ sqlite3 /litefs/blog.db "SELECT COUNT(*) FROM tags WHERE label = 'replica-test'"
1  # Should match primary
```

### Test 4: Check Logs for Errors

```bash
# On replica during insert
fly logs -a vereis-blog --machine 185e295b630538
```

**Expected:** Should still see "disk I/O error" in logs, but it's now expected and handled.

**Future improvement:** We could wrap the `super()` call to suppress this expected error from logs.

---

## Advantages of This Approach

1. ✅ **Works with current `ecto_middleware`** - No forking required
2. ✅ **No duplicate inserts** - Result handler prevents double-insert
3. ✅ **Clean separation** - Before handles forwarding, after handles result
4. ✅ **Consistent API** - Works with all Repo functions (insert, update, delete)
5. ✅ **Process-safe** - Process dictionary is isolated per request
6. ✅ **Testable** - Can test before and after middleware independently

## Disadvantages

1. ❌ **Wasted operation** - `super()` still attempts local write (blocked by LiteFS)
2. ❌ **Error logs** - Will log "disk I/O error" for every replica write
3. ❌ **Process dictionary** - Using process dict for control flow is a code smell
4. ❌ **Not official** - This is a workaround, not intended use of middleware

---

## Metrics to Monitor

After deploying this implementation, monitor:

1. **Error rate** - Should see consistent "disk I/O error" on replicas (expected)
2. **Write latency** - Should be same as before (forwarding time + wasted attempt)
3. **Replication lag** - Should be unaffected
4. **Memory usage** - Process dict usage should be minimal (cleaned immediately)

---

## Next Steps

1. ✅ Document the approach (this file)
2. ⏳ Implement `Blog.Repo.Middleware.LiteFS.ResultHandler`
3. ⏳ Update middleware configuration in `Blog.Repo`
4. ⏳ Test locally with multiple nodes
5. ⏳ Deploy to staging
6. ⏳ Monitor metrics
7. ⏳ Deploy to production

---

## Future: Contribute to EctoMiddleware

Once this is proven to work, we should:

1. Fork `ecto_middleware`
2. Add `Resolution.halt/2` support (see ECTO_MIDDLEWARE_IMPROVEMENTS.md)
3. Submit PR with use case and tests
4. If accepted, migrate to using halt mechanism
5. If rejected, document why and keep current approach
