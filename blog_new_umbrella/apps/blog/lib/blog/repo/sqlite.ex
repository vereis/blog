defmodule Blog.Repo.SQLite do
  use Ecto.Repo,
    otp_app: :blog,
    adapter: Ecto.Adapters.SQLite3
end