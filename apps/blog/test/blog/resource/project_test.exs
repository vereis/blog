defmodule Blog.Resource.ProjectTest do
  use Blog.DataCase, async: false

  alias Blog.Projects.Project
  alias Blog.Resource.Project, as: ProjectResource

  @temp_dir "tmp/test_projects"

  setup do
    # Clean up any existing temp directory
    File.rm_rf!(@temp_dir)
    File.mkdir_p!(@temp_dir)

    on_exit(fn ->
      File.rm_rf!(@temp_dir)
    end)

    :ok
  end

  describe "source/0" do
    test "returns correct path" do
      path = ProjectResource.source()
      assert String.ends_with?(path, "/priv/projects")
    end
  end

  describe "parse/1" do
    test "parses single project file" do
      content = """
      projects:
        - name: "Test Project"
          url: "https://example.com"
          description: "A test project"
      """

      File.write!("#{@temp_dir}/single.yaml", content)

      # Mock the source to point to our temp directory
      stub(ProjectResource, :source, fn -> @temp_dir end)
      result = ProjectResource.parse("single.yaml")

      assert result == [
               %{
                 id: nil,
                 name: "Test Project",
                 url: "https://example.com",
                 description: "A test project",
                 tags: []
               }
             ]
    end

    test "parses multiple projects file" do
      content = """
      projects:
        - name: "Project 1"
          url: "https://example1.com"
          description: "First project"
        - name: "Project 2"
          url: "https://example2.com"
          description: "Second project"
      """

      File.write!("#{@temp_dir}/multiple.yaml", content)

      stub(ProjectResource, :source, fn -> @temp_dir end)
      result = ProjectResource.parse("multiple.yaml")

      assert result == [
               %{
                 id: nil,
                 name: "Project 1",
                 url: "https://example1.com",
                 description: "First project",
                 tags: []
               },
               %{
                 id: nil,
                 name: "Project 2",
                 url: "https://example2.com",
                 description: "Second project",
                 tags: []
               }
             ]
    end

    test "raises error for invalid format" do
      content = """
      invalid: "format"
      """

      File.write!("#{@temp_dir}/invalid.yaml", content)

      stub(ProjectResource, :source, fn -> @temp_dir end)

      assert_raise RuntimeError, ~r/must have projects under a 'projects:' key/, fn ->
        ProjectResource.parse("invalid.yaml")
      end
    end
  end

  describe "import/1" do
    test "imports projects successfully" do
      parsed_projects = [
        %{name: "Test 1", url: "https://test1.com", description: "First test", tags: []},
        %{name: "Test 2", url: "https://test2.com", description: "Second test", tags: []}
      ]

      assert {:ok, imported_projects} = ProjectResource.import(parsed_projects)
      assert length(imported_projects) == 2

      project_names = Enum.map(imported_projects, & &1.name)
      assert "Test 1" in project_names
      assert "Test 2" in project_names

      # Verify they're in the database
      all_projects = Blog.Repo.SQLite.all(Project)
      assert length(all_projects) >= 2
    end

    test "imports projects with tags" do
      parsed_projects = [
        %{
          name: "Elixir Project",
          url: "https://example.com",
          description: "An Elixir project",
          tags: ["elixir", "phoenix"]
        },
        %{
          name: "Python Project",
          url: "https://example2.com",
          description: "A Python project",
          tags: ["python", "django"]
        }
      ]

      assert {:ok, imported_projects} = ProjectResource.import(parsed_projects)
      assert length(imported_projects) == 2

      # Verify tags were created and associated
      elixir_project = Enum.find(imported_projects, &(&1.name == "Elixir Project"))
      elixir_project_with_tags = Blog.Repo.SQLite.preload(elixir_project, :tags)

      tag_labels = Enum.map(elixir_project_with_tags.tags, & &1.label)
      assert "elixir" in tag_labels
      assert "phoenix" in tag_labels
    end
  end
end
