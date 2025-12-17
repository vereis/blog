# LiteFS Write Forwarding with EctoMiddleware

## Overview

This Phoenix application uses **LiteFS** for distributed SQLite replication across multiple regions, with **EctoMiddleware** to automatically forward write operations from replica nodes to the primary node via `:erpc`.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Request (Any Region)                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
                ┌───────────────────────┐
                │   Blog.Repo Operation  │
                │   (insert/update/etc)  │
                └───────────────────────┘
                            ↓
                ┌───────────────────────┐
                │  EctoMiddleware Layer  │
                └───────────────────────┘
                            ↓
                    ┌──────┴──────┐
                    │   Is Write?  │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
           YES (insert/update/delete)  NO (read)
              │                         │
    ┌─────────┴─────────┐               │
    │ Check Node Role:   │               │
    │ Primary or Replica?│               │
    └─────────┬─────────┘               │
              │                          │
      ┌───────┴────────┐                │
      │                │                │
   PRIMARY          REPLICA             │
      │                │                │
      │    ┌───────────┴─────────┐     │
      │    │ Find Primary Node:  │     │
      │    │ Check /litefs/.pri  │     │
      │    │ mary via :erpc      │     │
      │    └───────────┬─────────┘     │
      │                │                │
      │    ┌───────────┴─────────┐     │
      │    │ Forward to Primary: │     │
      │    │ :erpc.call(...)     │     │
      │    └───────────┬─────────┘     │
      │                │                │
      └────────┬───────┘                │
               │                        │
        ┌──────┴──────┐          ┌─────┴─────┐
        │ Execute on  │          │ Execute   │
        │ Primary DB  │          │ Locally   │
        └──────┬──────┘          └─────┬─────┘
               │                        │
               ↓                        ↓
        ┌────────────────────────────────────┐
        │  LiteFS Replicates to All Regions  │
        └────────────────────────────────────┘
```

## Implementation

### 1. Dependencies

```elixir
# apps/blog/mix.exs
{:ecto_middleware, "~> 1.0"}
```

### 2. Repo Configuration

```elixir
# apps/blog/lib/blog/repo.ex
defmodule Blog.Repo do
  use Ecto.Repo, otp_app: :blog, adapter: Ecto.Adapters.SQLite3
  use EctoMiddleware

  @write_actions [:insert, :insert!, :update, :update!, :delete, :delete!, 
                  :insert_or_update, :insert_or_update!]

  def middleware(action, _resource) when action in @write_actions do
    [Blog.Repo.Middleware.LiteFS, EctoMiddleware.Super]
  end

  def middleware(_action, _resource) do
    [EctoMiddleware.Super]
  end
end
```

### 3. LiteFS Middleware

```elixir
# apps/blog/lib/blog/repo/middleware/litefs.ex
defmodule Blog.Repo.Middleware.LiteFS do
  @behaviour EctoMiddleware
  @primary_file "/litefs/.primary"

  @impl EctoMiddleware
  def middleware(resource, %EctoMiddleware.Resolution{} = resolution) do
    case primary_status() do
      :primary -> resource
      {:replica, _} -> forward_to_primary(resource, resolution)
      {:error, :not_litefs} -> resource
    end
  end

  defp primary_status do
    case File.read(@primary_file) do
      {:ok, hostname} -> {:replica, String.trim(hostname)}
      {:error, :enoent} -> :primary
      {:error, _} -> {:error, :not_litefs}
    end
  end

  defp forward_to_primary(resource, resolution) do
    # Find primary by checking which node doesn't have .primary file
    primary_node =
      [Node.self() | Node.list()]
      |> Enum.find(fn node ->
        case :erpc.call(node, File, :exists?, [@primary_file]) do
          false -> true
          true -> false
        end
      end)

    # Forward the operation to primary
    :erpc.call(primary_node, resolution.repo, resolution.action, 
               [resource, get_opts(resolution.args)])
  end

  defp get_opts(args) do
    case args do
      [_resource, opts] when is_list(opts) -> opts
      [_resource, _id, opts] when is_list(opts) -> opts
      _ -> []
    end
  end
end
```

## How It Works

### Primary Node Discovery

**Challenge:** LiteFS and Erlang use different addressing schemes:
- LiteFS: `e829424aee6108.vm.vereis-blog.internal`
- Erlang: `vereis-blog-01KC...@fdaa:0:cf14:a7b:4a1:e0a0:8459:2`

**Solution:** Check all connected nodes to see which is primary:

```elixir
# Primary nodes don't have /litefs/.primary file
# Replica nodes have /litefs/.primary containing primary's machine ID

primary_node =
  [Node.self() | Node.list()]
  |> Enum.find(fn node ->
    !(:erpc.call(node, File, :exists?, ["/litefs/.primary"]))
  end)
```

This works because:
1. `dns_cluster` already connected all nodes
2. We just ask each node if it has the `.primary` file
3. The node without it is the primary

### Write Operation Flow

1. **Application calls:** `Repo.insert(%Post{...})`
2. **Middleware intercepts** before Ecto.Repo execution
3. **Check role:** Read `/litefs/.primary` file
4. **If replica:**
   - Find primary node via `:erpc` file checks
   - Forward: `:erpc.call(primary, Repo, :insert, [post, opts])`
   - Return result
5. **If primary:** Execute locally
6. **LiteFS replicates** data to replicas asynchronously

## Usage Examples

### Application Code (Unchanged!)

```elixir
# Controllers, LiveViews, etc. work exactly the same
def create(conn, %{"post" => post_params}) do
  case Blog.Repo.insert(changeset) do  # Automatically forwarded if needed
    {:ok, post} -> ...
    {:error, changeset} -> ...
  end
end
```

### Testing Write Forwarding

```elixir
# SSH into any replica
fly ssh console -a vereis-blog -C "/app/bin/blog_web remote" --machine <replica-id>

# Test write operation
iex> alias Blog.Repo
iex> alias Blog.Tags.Tag
iex> Repo.insert(%Tag{label: "test-from-replica"})
{:ok, %Tag{id: 22, label: "test-from-replica", ...}}

# Verify on primary
fly ssh console -a vereis-blog -C "/app/bin/blog_web remote" --machine <primary-id>
iex> Repo.get_by(Tag, label: "test-from-replica")
%Tag{id: 22, ...}
```

## Performance

| Operation | Location | Latency |
|-----------|----------|---------|
| Read (local) | Any node | 1-5ms |
| Write (primary) | Primary node | 1-5ms |
| Write (replica→primary) | US → London | ~80ms |
| Write (replica→primary) | Tokyo → London | ~120ms |

## Deployment

### Current Infrastructure

| Region | Location | Role | Machine ID |
|--------|----------|------|------------|
| **lhr** | London, UK | Primary | e829424aee6108 |
| **iad** | Ashburn, Virginia (US) | Replica | 185e295b630538 |
| **nrt** | Tokyo, Japan | Replica | 784e666f15eee8 |

### Environment Variables

```toml
# fly.toml
[env]
  RELEASE_NAME = 'blog_web'  # Critical for Erlang cluster
  DNS_CLUSTER_QUERY = 'vereis-blog.internal'
  DATABASE_PATH = '/var/lib/litefs/blog.db'
  PHX_SERVER = 'true'
  ECTO_IPV6 = 'true'
```

## Monitoring & Debugging

### Check Node Status

```elixir
# Check if current node is primary or replica
File.exists?("/litefs/.primary")
# false = primary, true = replica

# View primary hostname (on replica)
File.read!("/litefs/.primary")
# => "e829424aee6108"

# Check cluster connectivity
Node.list()
# => [:"vereis-blog-...@fdaa:...", ...]

# Find primary node
[Node.self() | Node.list()]
|> Enum.find(&(!:erpc.call(&1, File, :exists?, ["/litefs/.primary"])))
```

### Common Issues

**Issue:** `:erpc.call` returns `{:erpc, :noconnection}`
- **Cause:** Nodes not connected via Erlang distribution
- **Fix:** Check `DNS_CLUSTER_QUERY` and `RELEASE_NAME` env vars

**Issue:** Writes fail with `SQLITE_READONLY`
- **Cause:** Trying to write to replica without forwarding
- **Fix:** Ensure middleware is configured in `Blog.Repo`

**Issue:** Primary node not found
- **Cause:** No node in cluster without `.primary` file
- **Fix:** Check LiteFS configuration and primary election

## Benefits

1. ✅ **Transparent** - No application code changes
2. ✅ **Read Performance** - Reads execute locally
3. ✅ **Global Writes** - Write from any region
4. ✅ **Type Safe** - Preserves Ecto return types
5. ✅ **Error Handling** - Errors propagate correctly
6. ✅ **WebSocket Support** - No HTTP proxy blocking

## Trade-offs

1. ⚠️ **Write Latency** - Replica writes incur network roundtrip
2. ⚠️ **Single Write Point** - All writes go to primary
3. ⚠️ **Eventual Consistency** - Reads may lag writes slightly
4. ⚠️ **Primary Dependency** - Primary node required for writes

## Resources

- [EctoMiddleware](https://github.com/vereis/ecto_middleware) - Middleware pattern for Ecto
- [LiteFS Docs](https://fly.io/docs/litefs/) - Distributed SQLite
- [Fly.io Multi-Region](https://fly.io/docs/reference/regions/) - Region deployment
- [ERPC Documentation](https://www.erlang.org/doc/apps/kernel/erpc.html) - Remote procedure calls
