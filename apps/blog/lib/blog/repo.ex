defmodule Blog.Repo do
  use Ecto.Repo,
    otp_app: :blog,
    adapter: Ecto.Adapters.SQLite3

  use EctoMiddleware.Repo

  @impl EctoMiddleware.Repo
  def middleware(_action, _resource) do
    []
  end
end
