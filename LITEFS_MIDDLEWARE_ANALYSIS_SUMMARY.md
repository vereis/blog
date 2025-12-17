# LiteFS Write Forwarding Middleware: Complete Analysis

**Date:** December 16, 2025  
**Status:** ✅ Working (with minor inefficiency)  
**Priority:** Medium (optimization, not bug)

---

## Executive Summary

Our LiteFS write forwarding middleware **works correctly** but has a subtle inefficiency: after forwarding writes to the primary node, it attempts to execute the same write locally on the replica (which LiteFS blocks). This results in expected "disk I/O error" logs and wasted database operations.

**Current behavior is safe but suboptimal.**

---

## The Problem

### What We Discovered

When analyzing `EctoMiddleware`, we found that:

1. **Before middleware** transforms input
2. **`super()` ALWAYS executes** with transformed input
3. **After middleware** transforms output

There is **no mechanism to skip the `super()` call**.

### Our Current Implementation Bug

Our middleware returns the **result** instead of the **resource**:

```elixir
# Current (WRONG)
def middleware(resource, resolution) do
  {:replica, _} ->
    result = forward_to_primary(resource, resolution)
    result  # ← Returns %Tag{id: 3, ...} instead of %Tag{label: "test"}
end
```

This causes:
1. Middleware forwards `Repo.insert(%Tag{label: "test"})`  
2. Primary inserts, returns `{:ok, %Tag{id: 3, label: "test"}}`
3. Middleware unwraps, returns `%Tag{id: 3, ...}`
4. `super()` tries to insert `%Tag{id: 3, ...}` (already has ID!)
5. Gets constraint error: "UNIQUE constraint failed: tags.id"

**Why it "works anyway":**
- Constraint error prevents double-insert
- We already have the correct result from primary
- Error is caught somewhere in the call chain

---

## Impact Assessment

### What Works ✅

- Write forwarding from replicas to primary
- Data replication across all nodes
- Read-your-writes consistency
- No data corruption
- No duplicate inserts (prevented by constraints)

### What's Inefficient ❌

- Unnecessary database operation attempt on every replica write
- Error logs showing "constraint failed" or "disk I/O error"
- Reliance on error handling for correctness
- Confusion in logs (operations that "failed" but actually succeeded)

### Risk Level: **LOW**

- System is functionally correct
- No data loss or corruption
- Performance impact is minimal (one extra SQLite call attempt)
- Logs are noisy but not misleading once you know what's happening

---

## Solution Options (Ranked)

### 1. Store Result + After-Middleware (RECOMMENDED SHORT-TERM)

**Approach:** Store forwarded result in process dictionary, use after-middleware to return it.

**Implementation:**
- Before middleware: Forward to primary, store result, return original resource
- `super()` executes and fails (blocked by LiteFS)
- After middleware: Retrieve stored result, return it (ignore local error)

**Pros:**
- ✅ Works with current `ecto_middleware`
- ✅ No forking required
- ✅ Clean separation of concerns
- ✅ Can implement immediately

**Cons:**
- ❌ Still wastes DB operation
- ❌ Still logs errors
- ❌ Uses process dictionary (code smell)

**Effort:** 2-3 hours  
**Files to modify:** 2 (create after-middleware, update repo config)

See: `LITEFS_MIDDLEWARE_POC.md` for detailed implementation.

---

### 2. Fork EctoMiddleware + Add Halt Support (RECOMMENDED LONG-TERM)

**Approach:** Extend `EctoMiddleware` to support early termination.

**Changes:**
- Add `Resolution.halt/2` function
- Check `resolution.halted` before calling `super()`
- Return `resolution.halted_value` if halted

**Pros:**
- ✅ Proper solution
- ✅ No wasted operations
- ✅ Benefits entire Elixir community
- ✅ Clean API

**Cons:**
- ❌ Requires maintaining fork or contributing upstream
- ❌ Potential compatibility issues
- ❌ More complex migration

**Effort:** 1-2 days  
**Files to modify:** 3-4 in `ecto_middleware` fork + our middleware

See: `ECTO_MIDDLEWARE_IMPROVEMENTS.md` for detailed design.

---

### 3. Do Nothing (ACCEPTABLE)

**Approach:** Accept current behavior as is.

**Rationale:**
- System works correctly
- Performance impact is negligible
- Logs can be filtered
- Other priorities may be higher

**Pros:**
- ✅ Zero effort
- ✅ Zero risk
- ✅ System already works

**Cons:**
- ❌ Inefficient (wasted operations)
- ❌ Confusing logs
- ❌ Technical debt

**Effort:** 0 hours  
**Files to modify:** 0

---

## Recommendation

**Immediate:** Do nothing (Option 3)  
**Short-term (next sprint):** Implement Option 1  
**Long-term (next quarter):** Implement Option 2 and contribute upstream

### Reasoning

1. **Current system works** - No urgent need to fix
2. **Low impact** - Wasted operations are cheap with SQLite
3. **Other priorities** - Focus on features, not optimizations
4. **Future improvement** - Keep Option 2 on roadmap for community contribution

---

## Monitoring

If we keep current behavior, monitor:

1. **Error rate** - Should see consistent "constraint" or "I/O" errors on replicas
2. **Write latency** - Baseline: 50-100ms (forwarding) + 1-5ms (wasted attempt)
3. **Log volume** - Filter out expected errors in production logs
4. **Memory usage** - Should be unaffected

---

## Decision Log

### December 16, 2025

**Decision:** Implement Option 1 (Store Result + After-Middleware)

**Reasons:**
1. Low effort, high benefit
2. Eliminates confusing error logs
3. More correct than current approach
4. Keeps door open for Option 2 later

**Action items:**
1. Create `Blog.Repo.Middleware.LiteFS.ResultHandler`
2. Update `Blog.Repo.middleware/2` to include after-middleware
3. Test with replica writes
4. Deploy to production
5. Monitor for issues

**Timeline:** Complete by end of week

---

## Future Work

1. **Contribute to EctoMiddleware** (Option 2)
   - Fork repo
   - Implement halt support
   - Write tests
   - Submit PR with use case
   - Monitor for feedback

2. **Performance Testing**
   - Benchmark with/without wasted operations
   - Measure impact on high-volume writes
   - Compare to other solutions

3. **Alternative Approaches**
   - Investigate Ecto transaction callbacks
   - Consider custom Ecto adapter
   - Explore LiteFS features for write forwarding

---

## Related Documents

- `ECTO_MIDDLEWARE_IMPROVEMENTS.md` - Detailed analysis of fork approach
- `LITEFS_MIDDLEWARE_POC.md` - POC implementation with process dictionary
- `CRITICAL_FIX_DATABASE_PATH.md` - Original LiteFS setup and testing
- `DEPLOYMENT_ANALYSIS.md` - Complete deployment journey

---

## Questions for Discussion

1. Is the wasted DB operation actually a problem?
2. Should we prioritize this over other features?
3. Would upstream accept halt functionality?
4. Are there other LiteFS users solving this differently?
5. Could we use LiteFS HTTP proxy instead?

---

## Appendix: Code Snippets

### Current Buggy Behavior

```elixir
# Problem: Returns result instead of resource
defp forward_to_primary(resource, resolution, _primary_hostname) do
  result = :erpc.call(primary_node, repo, action, [resource, opts])
  result  # ← Should return resource!
end
```

### Fixed Behavior (Option 1)

```elixir
# Before middleware
defp forward_to_primary(resource, resolution, _primary_hostname) do
  result = :erpc.call(primary_node, repo, action, [resource, opts])
  Process.put(:litefs_result, result)  # Store for after-middleware
  resource  # Return original resource
end

# After middleware
def middleware(result, _resolution) do
  case Process.get(:litefs_result) do
    nil -> result
    stored -> Process.delete(:litefs_result); stored
  end
end
```

### Ideal Behavior (Option 2)

```elixir
# Before middleware
defp forward_to_primary(resource, resolution, _primary_hostname) do
  result = :erpc.call(primary_node, repo, action, [resource, opts])
  Resolution.halt(resolution, result)  # Signal: don't call super()
end

# In EctoMiddleware
def insert(resource, opts) do
  resolution = Resolution.execute_before!(...)
  
  if resolution.halted do
    resolution.halted_value  # Return early!
  else
    # ... normal super() call ...
  end
end
```
