defmodule Blog.Projects do
  @moduledoc "Context module for managing projects."

  alias Blog.Projects.Project
  alias Blog.Repo.SQLite

  require Logger

  @doc """
  Gets a single project by ID or filters.
  """
  @spec get_project(id :: integer()) :: Project.t() | nil
  @spec get_project(filters :: Keyword.t()) :: Project.t() | nil
  def get_project(project_id) when is_integer(project_id) do
    get_project(id: project_id)
  end

  def get_project(filters) do
    filters
    |> Keyword.put_new(:limit, 1)
    |> Project.query()
    |> SQLite.one()
    |> SQLite.preload(:tags)
  rescue
    exception ->
      if fts_error?(exception) do
        Logger.warning("FTS query error in get_project/1", error: Exception.message(exception))
        nil
      else
        reraise(exception, __STACKTRACE__)
      end
  end

  @doc """
  Lists projects with optional filters.
  """
  @spec list_projects(filters :: Keyword.t()) :: [Project.t()]
  def list_projects(filters \\ []) do
    filters
    |> Project.query()
    |> SQLite.all()
    |> SQLite.preload(:tags)
  rescue
    exception ->
      if fts_error?(exception) do
        Logger.warning("FTS query error in list_projects/1", error: Exception.message(exception))
        []
      else
        reraise(exception, __STACKTRACE__)
      end
  end

  @doc """
  Creates or updates a project with the given attributes.
  """
  @spec upsert_project(attrs :: map()) :: {:ok, Project.t()} | {:error, Ecto.Changeset.t()}
  def upsert_project(attrs) do
    (get_project(id: attrs.id) || %Project{})
    |> Project.changeset(attrs)
    |> SQLite.insert_or_update()
  end

  # Check if an exception is related to FTS queries
  defp fts_error?(%Exqlite.Error{statement: statement}) when is_binary(statement) do
    String.contains?(statement, "projects_fts") and String.contains?(statement, "MATCH")
  end

  defp fts_error?(_exception), do: false
end
