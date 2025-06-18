defmodule Blog.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :blog

  @spec migrate(Ecto.Repo.t()) :: :ok
  def migrate(Blog.Repo.Postgres) do
    load_app()

    {:ok, _repo_pid, _migrated_versions} =
      Ecto.Migrator.with_repo(Blog.Repo.Postgres, &Ecto.Migrator.run(&1, :up, all: true))

    :ok
  end

  def migrate(Blog.Repo.SQLite) do
    load_app()

    {:ok, _repo_pid, _migrated_versions} =
      Ecto.Migrator.with_repo(Blog.Repo.SQLite, &Ecto.Migrator.run(&1, :up, all: true))

    :ok
  end

  @spec rollback(Ecto.Repo.t(), integer()) :: :ok
  def rollback(repo, version) do
    load_app()

    {:ok, _repo_pid, _migrated_versions} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))

    :ok
  end

  defp load_app do
    Application.load(@app)
  end
end
