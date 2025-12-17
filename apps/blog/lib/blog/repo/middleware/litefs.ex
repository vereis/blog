defmodule Blog.Repo.Middleware.LiteFS do
  @moduledoc """
  Middleware that forwards write operations to the primary LiteFS node using :erpc.

  This middleware checks if the current node is a LiteFS replica by looking for the 
  `/litefs/.primary` file. If it exists, the middleware forwards the write operation
  to the primary node via `:erpc.call/4`.

  ## Architecture

  - **Primary node**: `/litefs/.primary` file does NOT exist
  - **Replica node**: `/litefs/.primary` file exists and contains the primary's hostname

  ## How it works

  1. Before a write operation executes, this middleware checks the node's role
  2. If we're on the primary, the operation executes locally (pass-through)
  3. If we're on a replica, the operation is forwarded to the primary via :erpc
  4. The result from the primary is returned to the caller

  ## Example

      # On replica node, this will be forwarded to primary:
      Blog.Repo.insert(%Post{title: "Hello"})
      
      # On primary node, this executes locally:
      Blog.Repo.insert(%Post{title: "Hello"})

  ## Error Handling

  If `:erpc.call/4` fails (network issues, primary down, etc.), the error is raised
  back to the caller. The middleware does NOT retry or fallback to local execution,
  as executing writes on a replica would cause SQLite to return `SQLITE_READONLY` errors.
  """

  @behaviour EctoMiddleware

  @primary_file "/litefs/.primary"

  @impl EctoMiddleware
  def middleware(resource, %EctoMiddleware.Resolution{} = resolution) do
    case primary_status() do
      :primary ->
        # We're the primary - execute locally (pass through)
        resource

      {:replica, primary_hostname} ->
        # We're a replica - forward to primary via :erpc
        forward_to_primary(resource, resolution, primary_hostname)

      {:error, :not_litefs} ->
        # Not running in LiteFS environment (dev/test) - execute locally
        resource
    end
  end

  # Determine if we're primary or replica
  defp primary_status do
    case File.read(@primary_file) do
      {:ok, hostname} ->
        # File exists = we're a replica, content is primary's hostname
        {:replica, String.trim(hostname)}

      {:error, :enoent} ->
        # File doesn't exist = we're the primary
        :primary

      {:error, _reason} ->
        # File doesn't exist and not ENOENT = not in LiteFS environment
        {:error, :not_litefs}
    end
  end

  # Forward the operation to primary using :erpc
  defp forward_to_primary(resource, resolution, _primary_short_hostname) do
    %{
      repo: repo,
      action: action,
      args: args
    } = resolution

    # Find the primary node by checking which node in the cluster doesn't have a .primary file
    # This works because only replicas have the /litefs/.primary file
    primary_node =
      Enum.find([Node.self() | Node.list()], fn node ->
        if :erpc.call(node, File, :exists?, [@primary_file]) do
          # No .primary file = this is the primary
          false
        else
          true
        end

        # Has .primary file = this is a replica
      end)

    if !primary_node do
      raise "Unable to find primary node in Erlang cluster. Connected nodes: #{inspect(Node.list())}"
    end

    # Get the opts (second argument for most Repo functions)
    opts =
      case args do
        [_resource, opts] when is_list(opts) -> opts
        [_resource, _id, opts] when is_list(opts) -> opts
        _ -> []
      end

    # Forward the call to the primary node
    # The resource has already been processed by any before-middleware,
    # so we just need to execute the repo action on the primary
    case :erpc.call(primary_node, repo, action, [resource, opts]) do
      {:ok, result} ->
        # For operations that return {:ok, result}, return just the result
        # since the middleware expects the unwrapped value
        result

      {:error, _reason} = error ->
        # For operations that return {:error, reason}, re-raise as they would locally
        # This maintains the same error semantics as local execution
        raise "Write operation failed on primary: #{inspect(error)}"

      result ->
        # For bang! operations or other return types, return as-is
        result
    end
  rescue
    error in ErlangError ->
      # :erpc.call failed (node unreachable, timeout, etc.)
      reraise RuntimeError,
              """
              Failed to forward write operation to primary node.

              This typically means:
              1. The primary node is unreachable
              2. Network issues between regions
              3. The Erlang cluster is not properly connected

              Original error: #{Exception.message(error)}
              """,
              __STACKTRACE__
  end
end
