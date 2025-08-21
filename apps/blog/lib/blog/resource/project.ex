defmodule Blog.Resource.Project do
  @moduledoc """
  Resource implementation for importing projects.

  Implements the Blog.Resource behaviour to provide project-specific
  import functionality. Supports both single project files and files
  with multiple projects under a 'projects:' key.
  """

  @behaviour Blog.Resource

  alias Blog.Projects
  alias Blog.Projects.Project

  @impl Blog.Resource
  def source do
    case Blog.env() do
      :dev ->
        "apps/blog/priv/projects"

      _other ->
        :blog
        |> :code.priv_dir()
        |> Path.join("projects")
    end
  end

  @impl Blog.Resource
  def parse(filename) do
    file_data =
      __MODULE__.source()
      |> Path.join(filename)
      |> File.read!()
      |> YamlElixir.read_from_string!()

    case file_data do
      # Multiple projects under a "projects" key
      %{"projects" => projects} when is_list(projects) ->
        Enum.map(projects, &normalize_project/1)

      # Single project at root level (must have name, url, description)
      %{"name" => _name, "url" => _url, "description" => _description} = project ->
        normalize_project(project)

      unexpected ->
        raise "Project file #{filename} must either have projects under a 'projects:' key or be a single project with name, url, and description. Got: #{inspect(unexpected)}"
    end
  end

  @impl Blog.Resource
  def import(parsed_projects) do
    imported_projects =
      for project_attrs <- parsed_projects do
        {:ok, %Project{} = imported_project} = Projects.create_project(project_attrs)
        imported_project
      end

    {:ok, imported_projects}
  end

  defp normalize_project(project) do
    %{
      name: project["name"],
      url: project["url"],
      description: project["description"]
    }
  end
end
