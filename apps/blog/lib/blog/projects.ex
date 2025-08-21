defmodule Blog.Projects do
  @moduledoc "Context module for managing projects."

  alias Blog.Projects.Project
  alias Blog.Repo.SQLite

  @doc """
  Lists all projects.
  """
  @spec list_projects() :: [Project.t()]
  def list_projects do
    SQLite.all(Project)
  end

  @doc """
  Gets a single project by ID.
  """
  @spec get_project(integer()) :: Project.t() | nil
  def get_project(id) do
    SQLite.get(Project, id)
  end

  @doc """
  Creates a project.
  """
  @spec create_project(map()) :: {:ok, Project.t()} | {:error, Ecto.Changeset.t()}
  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> SQLite.insert()
  end
end
