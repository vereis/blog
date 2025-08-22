defmodule Blog.ProjectsTest do
  use Blog.DataCase, async: false

  alias Blog.Projects
  alias Blog.Projects.Project

  describe "list_projects/0" do
    test "returns all projects" do
      insert(:project, name: "Project 1")
      insert(:project, name: "Project 2")

      projects = Projects.list_projects()
      project_names = Enum.map(projects, & &1.name)

      assert "Project 1" in project_names
      assert "Project 2" in project_names
    end

    test "returns empty list when no projects" do
      assert Projects.list_projects() == []
    end
  end

  describe "get_project/1" do
    test "returns project when exists" do
      project = insert(:project, name: "Test Project")

      assert %Project{name: "Test Project"} = Projects.get_project(project.id)
    end

    test "returns nil when project doesn't exist" do
      assert Projects.get_project(999) == nil
    end
  end

  describe "list_projects/1 with search" do
    setup do
      project1 =
        insert(:project,
          name: "Elixir Phoenix App",
          description: "Web application built with Phoenix LiveView"
        )

      project2 =
        insert(:project,
          name: "Python Data Tool",
          description: "Data processing script in Python"
        )

      {:ok, project1: project1, project2: project2}
    end

    test "searches projects by name", %{project1: project1} do
      projects = Projects.list_projects(search: "Elixir")

      assert length(projects) == 1
      assert hd(projects).id == project1.id
    end

    test "searches projects by description", %{project1: project1} do
      projects = Projects.list_projects(search: "Phoenix")

      assert length(projects) == 1
      assert hd(projects).id == project1.id
    end

    test "returns empty list when no matches" do
      projects = Projects.list_projects(search: "NonExistentTerm")

      assert projects == []
    end

    test "handles invalid FTS queries gracefully", %{project1: _project1, project2: _project2} do
      # Some invalid queries get sanitized and return all results
      projects = Projects.list_projects(search: "AND")
      assert length(projects) >= 2

      # Others cause SQL errors and return empty results
      projects = Projects.list_projects(search: "elixir |||")
      assert projects == []

      projects = Projects.list_projects(search: "\"unterminated quote")
      assert projects == []
    end

    test "handles empty search", %{project1: _project1, project2: _project2} do
      projects = Projects.list_projects(search: "")

      assert length(projects) >= 2
    end
  end

  describe "get_project/1 with search" do
    setup do
      insert(:project,
        name: "Elixir Phoenix App",
        description: "Web application built with Phoenix"
      )

      :ok
    end

    test "finds project by search term" do
      project = Projects.get_project(search: "Elixir")

      assert project.name == "Elixir Phoenix App"
    end

    test "returns nil when no matches" do
      project = Projects.get_project(search: "NonExistentTerm")

      assert project == nil
    end

    test "handles invalid FTS queries gracefully" do
      # Some invalid queries get sanitized and return first result
      project = Projects.get_project(search: "AND")
      assert project.name == "Elixir Phoenix App"

      # Others cause SQL errors and return nil
      project = Projects.get_project(search: "elixir |||")
      assert is_nil(project)

      project = Projects.get_project(search: "\"unterminated quote")
      assert is_nil(project)
    end
  end

  describe "upsert_project/1" do
    test "creates new project when id doesn't exist" do
      attrs = %{
        id: 1,
        name: "New Project",
        url: "https://example.com",
        description: "A test project"
      }

      assert {:ok, %Project{} = project} = Projects.upsert_project(attrs)
      assert project.name == "New Project"
      assert project.url == "https://example.com"
      assert project.description == "A test project"
    end

    test "updates existing project when id exists" do
      existing = insert(:project, name: "Old Name")

      attrs = %{
        id: existing.id,
        name: "Updated Name",
        url: existing.url,
        description: existing.description
      }

      assert {:ok, %Project{} = project} = Projects.upsert_project(attrs)
      assert project.id == existing.id
      assert project.name == "Updated Name"
    end

    test "handles tag associations" do
      tag1 = insert(:tag, label: "elixir")
      tag2 = insert(:tag, label: "ecto")

      attrs = %{
        id: 1,
        name: "Test Project",
        url: "https://example.com",
        description: "A test project",
        tag_ids: [tag1.id, tag2.id]
      }

      assert {:ok, %Project{} = project} = Projects.upsert_project(attrs)
      project_with_tags = Blog.Repo.SQLite.preload(project, :tags)

      assert length(project_with_tags.tags) == 2
      tag_labels = Enum.map(project_with_tags.tags, & &1.label)
      assert "elixir" in tag_labels
      assert "ecto" in tag_labels
    end

    test "returns error changeset with invalid attributes" do
      attrs = %{id: 1, name: ""}

      assert {:error, %Ecto.Changeset{}} = Projects.upsert_project(attrs)
    end
  end

  describe "FTS error handling" do
    test "list_projects/1 gracefully handles invalid FTS queries" do
      # Invalid queries that can't be sanitized return empty results
      insert(:project, name: "Test Project")

      projects = Projects.list_projects(search: "elixir ||| invalid")
      assert projects == []

      projects = Projects.list_projects(search: "\"unterminated quote")
      assert projects == []

      # Complex operators also cause SQL errors
      projects = Projects.list_projects(search: "AND OR NOT")
      assert projects == []
    end

    test "get_project/1 gracefully handles invalid FTS queries" do
      _project = insert(:project, name: "Test Project")

      # Invalid queries that can't be sanitized return nil
      result = Projects.get_project(search: "\"unterminated quote")
      assert is_nil(result)

      result = Projects.get_project(search: "elixir ||| invalid")
      assert is_nil(result)

      # Complex operators also cause SQL errors
      result = Projects.get_project(search: "AND OR NOT")
      assert is_nil(result)
    end
  end
end
