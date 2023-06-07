defmodule Blog.Migrator do
  @moduledoc false

  @start_apps [
    :ssl,
    :ecto,
    :ecto_sql
  ]

  @spec migrate() :: [{:ok, term(), term()}]
  def migrate do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Application.load(:blog)

    for repo <- Application.fetch_env!(:blog, :ecto_repos) do
      {:ok, _resp, _apps} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end
end
