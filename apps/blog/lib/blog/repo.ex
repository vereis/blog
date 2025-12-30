defmodule Blog.Repo do
  use Ecto.Repo,
    otp_app: :blog,
    adapter: Ecto.Adapters.SQLite3

  use EctoMiddleware.Repo

  @write_actions [:insert, :insert!, :update, :update!, :delete, :delete!, :insert_or_update, :insert_or_update!]

  @impl EctoMiddleware.Repo
  def middleware(action, _resource) when action in @write_actions do
    [EctoLiteFS.Middleware]
  end

  def middleware(_action, _resource) do
    []
  end
end
