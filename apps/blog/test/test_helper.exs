ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Blog.Repo.Postgres, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Blog.Repo.SQLite, :manual)

Mimic.copy(Blog.Resource.Post)
Mimic.copy(Blog.Resource.Image)
Mimic.copy(Blog.Resource.Project)
Mimic.copy(Vix.Vips.Image)
Mimic.copy(Req)
Mimic.copy(Blog.Lanyard.Presence)

{:ok, _} = Application.ensure_all_started(:ex_machina)
