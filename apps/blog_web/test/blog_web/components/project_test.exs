defmodule BlogWeb.Components.ProjectTest do
  use BlogWeb.ConnCase, async: true

  import Blog.Factory
  import Phoenix.LiveViewTest

  alias BlogWeb.Components.Project

  describe "list/1" do
    test "renders block empty state when no projects exist" do
      html =
        render_component(&Project.list/1,
          projects: [],
          loading: false,
          id: "test-projects"
        )

      assert html =~ "No Projects Found"
      assert html =~ ~s(class="empty-state")
      assert html =~ ~s(role="status")
      assert html =~ "No items"
    end

    test "renders list with single project" do
      project = build(:project, name: "My Project", description: "A cool project", tags: [])

      html =
        render_component(&Project.list/1,
          projects: [project],
          loading: false,
          id: "test-projects"
        )

      assert html =~ "My Project"
      assert html =~ "A cool project"
      assert html =~ "1 items"
    end

    test "renders list with multiple projects" do
      projects = [
        build(:project, name: "First Project", tags: []),
        build(:project, name: "Second Project", tags: []),
        build(:project, name: "Third Project", tags: [])
      ]

      html =
        render_component(&Project.list/1,
          projects: projects,
          loading: false,
          id: "test-projects"
        )

      assert html =~ "First Project"
      assert html =~ "Second Project"
      assert html =~ "Third Project"
      assert html =~ "3 items"
    end

    test "renders external link with proper attributes" do
      project = build(:project, name: "Test", url: "https://github.com/test/repo", tags: [])

      html =
        render_component(&Project.list/1,
          projects: [project],
          loading: false,
          id: "test-projects"
        )

      assert html =~ ~s(href="https://github.com/test/repo")
      assert html =~ ~s(target="_blank")
      assert html =~ ~s(rel="noopener noreferrer")
    end

    test "renders project index numbers" do
      projects = [
        build(:project, name: "First", tags: []),
        build(:project, name: "Second", tags: []),
        build(:project, name: "Third", tags: [])
      ]

      html =
        render_component(&Project.list/1,
          projects: projects,
          loading: false,
          id: "test-projects"
        )

      assert html =~ "#1"
      assert html =~ "#2"
      assert html =~ "#3"
    end

    test "renders tags when project has tags" do
      tag1 = build(:tag, label: "elixir")
      tag2 = build(:tag, label: "phoenix")
      project = build(:project, tags: [tag1, tag2])

      html =
        render_component(&Project.list/1,
          projects: [project],
          loading: false,
          id: "test-projects"
        )

      assert html =~ "elixir"
      assert html =~ "phoenix"
    end

    test "renders custom title" do
      html =
        render_component(&Project.list/1,
          projects: [],
          loading: false,
          id: "test-projects",
          title: "My Custom Title"
        )

      assert html =~ "My Custom Title"
    end

    test "uses default title when not provided" do
      html =
        render_component(&Project.list/1,
          projects: [],
          loading: false,
          id: "test-projects"
        )

      assert html =~ "Projects"
    end

    test "renders with custom DOM ID" do
      project = build(:project, tags: [])

      html =
        render_component(&Project.list/1,
          projects: [project],
          loading: false,
          id: "custom-id"
        )

      assert html =~ ~s(id="custom-id")
    end

    test "includes aria-label for accessibility" do
      project = build(:project, name: "Test Project", tags: [])

      html =
        render_component(&Project.list/1,
          projects: [project],
          loading: false,
          id: "test-projects"
        )

      assert html =~ ~s(aria-label="View project: Test Project")
    end
  end
end
