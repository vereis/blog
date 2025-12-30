defmodule Blog.Repo do
  use Ecto.Repo,
    otp_app: :blog,
    adapter: Ecto.Adapters.SQLite3

  use EctoMiddleware.Repo

  @doc """
  Configures middleware to run for each Repo action.

  Write operations are forwarded to the primary node via :erpc when running on a replica.
  """
  @impl EctoMiddleware.Repo
  def middleware(action, _resource) when is_write(_resource, action) do
    [EctoLiteFS.Middleware]
  end

  def middleware(_action, _resource) do
    []
  end
end
