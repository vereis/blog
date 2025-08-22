defmodule Blog.Resource.Project do
  @moduledoc """
  Resource implementation for importing projects.

  Implements the Blog.Resource behaviour to provide project-specific
  import functionality. All project files must have projects under a
  `projects:` key, whether they contain one or multiple projects.
  """

  @behaviour Blog.Resource

  alias Blog.Posts.Tag
  alias Blog.Projects
  alias Blog.Projects.Project
  alias Blog.Repo.SQLite

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

    # All files must have projects under a "projects" key
    projects_list =
      case file_data do
        %{"projects" => projects} when is_list(projects) ->
          projects

        unexpected ->
          raise "Project file #{filename} must have projects under a 'projects:' key, got: #{inspect(unexpected)}"
      end

    Enum.map(projects_list, fn project ->
      %{
        # Will be assigned during import
        id: nil,
        name: project["name"],
        url: project["url"],
        description: project["description"],
        tags: project["tags"] || []
      }
    end)
  end

  @impl Blog.Resource
  def import(parsed_projects) when is_list(parsed_projects) do
    # parsed_projects is already flattened by the generic import function
    all_projects = parsed_projects

    now =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)

    # Assign sequential IDs to projects
    project_attrs =
      all_projects
      |> Enum.with_index(1)
      |> Enum.map(fn {attrs, index} -> Map.put(attrs, :id, index) end)

    # Create tags first
    {_count, tags} =
      project_attrs
      |> Enum.flat_map(& &1.tags)
      |> Enum.uniq()
      |> Enum.map(&%{label: &1, inserted_at: now, updated_at: now})
      |> then(
        &SQLite.insert_all(
          Tag,
          &1,
          on_conflict: {:replace_all_except, [:id, :inserted_at, :updated_at]},
          returning: true
        )
      )

    tag_lookup_table = Map.new(tags, fn tag -> {tag.label, tag.id} end)

    # Import projects with tag associations and collect results
    imported_projects =
      for project <- project_attrs,
          project = Map.put(project, :tag_ids, Enum.map(project.tags, &tag_lookup_table[&1])) do
        {:ok, %Project{} = imported_project} = Projects.upsert_project(project)
        imported_project
      end

    {:ok, imported_projects}
  end
end
