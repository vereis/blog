defmodule Blog.Repo do
  use Ecto.Repo, otp_app: :blog, adapter: Ecto.Adapters.SQLite3, busy_timeout: :timer.seconds(10)
  use EctoUtils.Repo
end
