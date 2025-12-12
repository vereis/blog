defmodule Blog.ProjectsTest do
  use Blog.DataCase, async: false

  alias Blog.Projects

  describe "list_projects/1" do
    test "returns all projects" do
      project1 = insert(:project, name: "First Project")
      project2 = insert(:project, name: "Second Project")

      projects = Projects.list_projects()

      assert length(projects) == 2
      assert Enum.any?(projects, &(&1.id == project1.id))
      assert Enum.any?(projects, &(&1.id == project2.id))
    end

    test "returns empty list when no projects exist" do
      assert Projects.list_projects() == []
    end

    test "limits results" do
      insert(:project, name: "Project 1")
      insert(:project, name: "Project 2")
      insert(:project, name: "Project 3")

      projects = Projects.list_projects(limit: 2)

      assert length(projects) == 2
    end

    test "orders projects by name asc" do
      insert(:project, name: "Charlie")
      insert(:project, name: "Alice")
      insert(:project, name: "Bob")

      projects = Projects.list_projects(order_by: [asc: :name])

      assert [p1, p2, p3] = projects
      assert p1.name == "Alice"
      assert p2.name == "Bob"
      assert p3.name == "Charlie"
    end

    test "filters projects by tags" do
      elixir_tag = insert(:tag, label: "elixir")
      rust_tag = insert(:tag, label: "rust")
      web_tag = insert(:tag, label: "web")

      _project1 = insert(:project, name: "Elixir Library", tags: [elixir_tag])
      project2 = insert(:project, name: "Web Framework", tags: [elixir_tag, web_tag])
      project3 = insert(:project, name: "Rust CLI", tags: [rust_tag])

      elixir_projects = Projects.list_projects(tags: ["elixir"])
      assert length(elixir_projects) == 2

      web_projects = Projects.list_projects(tags: ["web"])
      assert length(web_projects) == 1
      assert hd(web_projects).id == project2.id

      rust_projects = Projects.list_projects(tags: ["rust"])
      assert length(rust_projects) == 1
      assert hd(rust_projects).id == project3.id
    end

    test "returns all projects when tags filter is empty list" do
      elixir_tag = insert(:tag, label: "elixir")
      rust_tag = insert(:tag, label: "rust")

      project1 = insert(:project, name: "Elixir Project", tags: [elixir_tag])
      project2 = insert(:project, name: "Rust Project", tags: [rust_tag])
      project3 = insert(:project, name: "No Tags Project", tags: [])

      projects = Projects.list_projects(tags: [])

      assert length(projects) == 3
      assert Enum.any?(projects, &(&1.id == project1.id))
      assert Enum.any?(projects, &(&1.id == project2.id))
      assert Enum.any?(projects, &(&1.id == project3.id))
    end

    test "returns all projects when tags filter is nil" do
      elixir_tag = insert(:tag, label: "elixir")
      rust_tag = insert(:tag, label: "rust")

      project1 = insert(:project, name: "Elixir Project", tags: [elixir_tag])
      project2 = insert(:project, name: "Rust Project", tags: [rust_tag])
      project3 = insert(:project, name: "No Tags Project", tags: [])

      projects = Projects.list_projects(tags: nil)

      assert length(projects) == 3
      assert Enum.any?(projects, &(&1.id == project1.id))
      assert Enum.any?(projects, &(&1.id == project2.id))
      assert Enum.any?(projects, &(&1.id == project3.id))
    end
  end

  describe "get_project/1" do
    test "gets project by ID" do
      project = insert(:project, name: "Test Project")

      assert fetched = Projects.get_project(project.id)
      assert fetched.id == project.id
      assert fetched.name == "Test Project"
    end

    test "gets project by name" do
      project = insert(:project, name: "Test Project")

      assert fetched = Projects.get_project(name: "Test Project")
      assert fetched.id == project.id
    end

    test "returns nil when project not found by ID" do
      assert Projects.get_project(999) == nil
    end

    test "returns nil when project not found by name" do
      assert Projects.get_project(name: "Nonexistent") == nil
    end

    test "filters by tags" do
      elixir_tag = insert(:tag, label: "elixir")
      rust_tag = insert(:tag, label: "rust")

      project1 = insert(:project, name: "Elixir Project", tags: [elixir_tag])
      _project2 = insert(:project, name: "Rust Project", tags: [rust_tag])

      assert fetched = Projects.get_project(name: "Elixir Project", tags: ["elixir"])
      assert fetched.id == project1.id

      assert Projects.get_project(name: "Elixir Project", tags: ["rust"]) == nil
    end
  end

  describe "create_project/1" do
    test "creates a project with valid attributes" do
      attrs = %{
        name: "Cool Library",
        url: "https://github.com/vereis/cool_library",
        description: "A really cool library"
      }

      assert {:ok, project} = Projects.create_project(attrs)
      assert project.name == "Cool Library"
      assert project.url == "https://github.com/vereis/cool_library"
      assert project.description == "A really cool library"
    end

    test "returns error with invalid attributes" do
      assert {:error, changeset} = Projects.create_project(%{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
      assert %{url: ["can't be blank"]} = errors_on(changeset)
      assert %{description: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error with duplicate name" do
      insert(:project, name: "Duplicate")

      assert {:error, changeset} =
               Projects.create_project(%{
                 name: "Duplicate",
                 url: "https://example.com",
                 description: "Description"
               })

      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "update_project/2" do
    test "updates project with valid attributes" do
      project = insert(:project, name: "Old Name")

      attrs = %{name: "New Name", url: "https://new-url.com"}

      assert {:ok, updated} = Projects.update_project(project, attrs)
      assert updated.name == "New Name"
      assert updated.url == "https://new-url.com"
    end

    test "returns error with invalid attributes" do
      project = insert(:project)

      assert {:error, changeset} = Projects.update_project(project, %{name: nil})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "upsert_project/1" do
    test "creates project when it doesn't exist" do
      attrs = %{
        name: "New Project",
        url: "https://example.com",
        description: "Description"
      }

      assert {:ok, project} = Projects.upsert_project(attrs)
      assert project.name == "New Project"
    end

    test "updates project when it exists" do
      existing = insert(:project, name: "Existing", url: "https://old.com")

      attrs = %{
        name: "Existing",
        url: "https://new.com",
        description: "Updated description"
      }

      assert {:ok, updated} = Projects.upsert_project(attrs)
      assert updated.id == existing.id
      assert updated.url == "https://new.com"
      assert updated.description == "Updated description"
    end
  end

  describe "delete_project/1" do
    test "deletes project" do
      project = insert(:project)

      assert {:ok, deleted} = Projects.delete_project(project)
      assert deleted.id == project.id
      assert Projects.get_project(project.id) == nil
    end
  end
end
