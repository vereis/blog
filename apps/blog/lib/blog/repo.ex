defmodule Blog.Repo do
  use Ecto.Repo,
    otp_app: :blog,
    adapter: Ecto.Adapters.SQLite3

  use EctoMiddleware

  @write_actions [:insert, :insert!, :update, :update!, :delete, :delete!, :insert_or_update, :insert_or_update!]

  @doc """
  Configures middleware to run for each Repo action.

  Write operations are forwarded to the primary node via :erpc when running on a replica.
  """
  def middleware(action, _resource) when action in @write_actions do
    # For write operations: forward to primary if we're a replica
    [Blog.Repo.Middleware.LiteFS, EctoMiddleware.Super]
  end

  def middleware(_action, _resource) do
    # For read operations: execute locally (no middleware needed)
    [EctoMiddleware.Super]
  end
end
