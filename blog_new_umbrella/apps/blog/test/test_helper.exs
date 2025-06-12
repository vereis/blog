ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Blog.Repo.Postgres, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Blog.Repo.SQLite, :manual)

Mimic.copy(Blog.Resource.Post)
Mimic.copy(Blog.Resource.Image)

{:ok, _} = Application.ensure_all_started(:ex_machina)
