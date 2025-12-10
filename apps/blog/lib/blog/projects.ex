defmodule Blog.Projects do
  @moduledoc false

  alias Blog.Projects.Project
  alias Blog.Repo

  @spec list_projects(Keyword.t()) :: [Project.t()]
  def list_projects(filters \\ []) do
    filters
    |> Keyword.put_new(:preload, :tags)
    |> Project.query()
    |> Repo.all()
  end

  @spec get_project(integer()) :: Project.t() | nil
  @spec get_project(Keyword.t()) :: Project.t() | nil
  def get_project(project_id) when is_integer(project_id) do
    get_project(id: project_id)
  end

  def get_project(filters) when is_list(filters) do
    filters
    |> Keyword.put(:limit, 1)
    |> Project.query()
    |> Repo.one()
  end

  @spec create_project(map()) :: {:ok, Project.t()} | {:error, Ecto.Changeset.t(Project.t())}
  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_project(Project.t(), map()) ::
          {:ok, Project.t()} | {:error, Ecto.Changeset.t(Project.t())}
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @spec upsert_project(map()) :: {:ok, Project.t()} | {:error, Ecto.Changeset.t(Project.t())}
  def upsert_project(attrs) when is_map(attrs) do
    case get_project(name: Map.get(attrs, :name)) do
      nil -> create_project(attrs)
      project -> update_project(project, attrs)
    end
  end

  @spec delete_project(Project.t()) ::
          {:ok, Project.t()} | {:error, Ecto.Changeset.t(Project.t())}
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end
end
