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

  describe "create_project/1" do
    test "creates project with valid attributes" do
      attrs = %{
        name: "New Project",
        url: "https://example.com",
        description: "A test project"
      }

      assert {:ok, %Project{} = project} = Projects.create_project(attrs)
      assert project.name == "New Project"
      assert project.url == "https://example.com"
      assert project.description == "A test project"
    end

    test "returns error changeset with invalid attributes" do
      attrs = %{name: ""}

      assert {:error, %Ecto.Changeset{}} = Projects.create_project(attrs)
    end
  end
end
