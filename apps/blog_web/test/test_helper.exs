ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Blog.Repo.Postgres, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Blog.Repo.SQLite, :manual)

Mimic.copy(Vix.Vips.Image)
