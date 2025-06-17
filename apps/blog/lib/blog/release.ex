defmodule Blog.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :blog

  @spec migrate() :: :ok
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _repo_pid, _migrated_versions} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    :ok
  end

  @spec rollback(Ecto.Repo.t(), integer()) :: :ok
  def rollback(repo, version) do
    load_app()
    {:ok, _repo_pid, _migrated_versions} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
    :ok
  end

  defp repos do
    # Only migrate SQLite in production for now
    Application.fetch_env!(@app, :ecto_repos) -- [Blog.Repo.Postgres]
  end

  defp load_app do
    Application.load(@app)
  end
end
