defmodule Blog.Repo do
  use Ecto.Repo, otp_app: :blog, adapter: Ecto.Adapters.SQLite3
  use EctoUtils.Repo
end
