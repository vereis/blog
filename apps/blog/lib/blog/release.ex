defmodule Blog.Release do
  @moduledoc """
  Release tasks for running migrations.

  Called by LiteFS on the primary node before starting the application.
  """

  @app :blog

  def migrate do
    load_app()

    for repo <- repos() do
      # Ensure database file exists before trying to connect
      ensure_database_file_exists(repo)

      # Use pool_size: 1 for migrations to avoid connection conflicts with SQLite/LiteFS
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true), pool_size: 1)
    end
  end

  defp ensure_database_file_exists(repo) do
    config = repo.config()
    db_path = Keyword.get(config, :database)

    IO.puts("Checking database at: #{db_path}")

    # If database doesn't exist, create it using sqlite3 command
    if File.exists?(db_path) do
      IO.puts("Database file already exists")

      # Use sqlite3 to create an empty database
      # Wait a moment for LiteFS to sync
    else
      IO.puts("Database doesn't exist, creating empty database...")

      case System.cmd("sqlite3", [db_path, ".databases"], stderr_to_stdout: true) do
        {output, 0} ->
          IO.puts("Database created successfully: #{output}")
          Process.sleep(1000)

        {error, code} ->
          IO.puts("Failed to create database (exit #{code}): #{error}")
          raise "Could not create database file"
      end
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
