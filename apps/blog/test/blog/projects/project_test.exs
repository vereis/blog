defmodule Blog.Projects.ProjectTest do
  use Blog.DataCase, async: false

  alias Blog.Projects.Project

  describe "changeset/2 - validation" do
    test "validates required fields" do
      changeset = Project.changeset(%Project{}, %{})

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
      assert %{url: ["can't be blank"]} = errors_on(changeset)
      assert %{description: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid project attributes" do
      changeset =
        Project.changeset(%Project{}, %{
          name: "Cool Elixir Library",
          url: "https://github.com/vereis/cool_library",
          description: "A really cool library that does cool things"
        })

      assert changeset.valid?
    end

    test "enforces unique name constraint" do
      attrs = %{
        name: "Unique Project",
        url: "https://example.com",
        description: "Description"
      }

      {:ok, _project} = %Project{} |> Project.changeset(attrs) |> Repo.insert()

      assert {:error, changeset} = %Project{} |> Project.changeset(attrs) |> Repo.insert()
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "handle_import/1 - YAML parsing" do
    test "parses projects.yaml with multiple projects" do
      yaml_content = """
      projects:
        - name: "Project One"
          url: "https://example.com/one"
          description: "First project"
        - name: "Project Two"
          url: "https://example.com/two"
          description: "Second project"
      """

      resource = %Blog.Content{content: yaml_content}
      attrs_list = Project.handle_import(resource)

      assert is_list(attrs_list)
      assert length(attrs_list) == 2

      [attrs1, attrs2] = attrs_list
      assert is_map(attrs1)
      assert is_map(attrs2)
      assert attrs1.name == "Project One"
      assert attrs2.name == "Project Two"
    end

    test "returns error for invalid YAML format" do
      yaml_content = "invalid: yaml"
      resource = %Blog.Content{content: yaml_content}

      assert {:error, ~s(YAML content does not contain 'projects' key with a list value, got: %{"invalid" => "yaml"})} =
               Project.handle_import(resource)
    end
  end

  describe "import/0 - resource import system" do
    test "imports projects from projects.yaml file" do
      assert {:ok, imported} = Project.import()

      assert length(imported) == 2
      assert Enum.any?(imported, &(&1.name == "Test Project"))
      assert Enum.any?(imported, &(&1.name == "Another Project"))

      # Check tags were imported and associated
      test_project = Project |> Repo.get_by!(name: "Test Project") |> Repo.preload(:tags)
      assert length(test_project.tags) == 2
      tag_labels = test_project.tags |> Enum.map(& &1.label) |> Enum.sort()
      assert tag_labels == ["elixir", "web"]

      another_project = Project |> Repo.get_by!(name: "Another Project") |> Repo.preload(:tags)
      assert length(another_project.tags) == 1
      assert hd(another_project.tags).label == "rust"
    end

    test "upserts projects based on name" do
      # First import
      assert {:ok, _} = Project.import()
      first_project = Repo.get_by(Project, name: "Test Project")

      # Second import should update, not duplicate
      assert {:ok, _} = Project.import()
      assert Repo.aggregate(Project, :count) == 2

      # Project should still have the same ID
      second_project = Repo.get_by(Project, name: "Test Project")
      assert first_project.id == second_project.id
    end
  end
end
