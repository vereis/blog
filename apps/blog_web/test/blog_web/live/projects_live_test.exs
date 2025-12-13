defmodule BlogWeb.ProjectsLiveTest do
  use BlogWeb.ConnCase

  import Blog.Factory
  import Phoenix.LiveViewTest

  describe ":index" do
    test "mounts successfully and displays projects list", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/projects")

      assert html =~ "Projects"
    end

    test "loads and displays projects after mount", %{conn: conn} do
      _project = insert(:project, name: "My First Project", url: "https://example.com")

      {:ok, view, _html} = live(conn, ~p"/projects")

      assert render(view) =~ "My First Project"
      assert has_element?(view, "a[href='https://example.com'][target='_blank']")
    end

    test "displays empty state when no projects exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      assert render(view) =~ "No projects found"
      assert render(view) =~ "Return home"
      assert has_element?(view, ".empty-state")
    end

    test "displays projects with metadata", %{conn: conn} do
      insert(:project,
        name: "Test Project",
        description: "A test project",
        url: "https://test.com",
        inserted_at: ~U[2024-01-15 10:00:00Z]
      )

      {:ok, view, _html} = live(conn, ~p"/projects")

      html = render(view)
      assert html =~ "Test Project"
      assert html =~ "A test project"
      assert html =~ "Jan 15, 2024"
    end

    test "displays projects with index numbers", %{conn: conn} do
      insert(:project,
        name: "First Project",
        url: "https://first.com",
        inserted_at: ~U[2024-01-20 10:00:00Z]
      )

      insert(:project,
        name: "Second Project",
        url: "https://second.com",
        inserted_at: ~U[2024-01-15 10:00:00Z]
      )

      {:ok, view, _html} = live(conn, ~p"/projects")

      html = render(view)
      assert html =~ "#1"
      assert html =~ "#2"
    end

    test "renders navbar with navigation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      assert has_element?(view, "header nav")
      assert has_element?(view, "a[href='/']", "Home")
      assert has_element?(view, "a[href='/posts']", "Posts")
    end

    test "sets page title to Projects", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      assert page_title(view) =~ "Projects"
    end

    test "navigates back to home via navbar", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      {:error, {:live_redirect, %{to: path}}} =
        view
        |> element("nav ul a[href='/']", "Home")
        |> render_click()

      assert path == ~p"/"
    end
  end

  describe "cross-LiveView navigation" do
    test "navigates to posts from projects", %{conn: conn} do
      {:ok, projects_view, _html} = live(conn, ~p"/projects")

      {:error, {:live_redirect, %{to: path}}} =
        projects_view
        |> element("a[href='/posts']", "Posts")
        |> render_click()

      assert path == ~p"/posts"
    end

    test "navigates to posts and renders correctly", %{conn: conn} do
      {:ok, projects_view, _html} = live(conn, ~p"/projects")

      {:ok, posts_view, _html} =
        projects_view
        |> element("a[href='/posts']", "Posts")
        |> render_click()
        |> follow_redirect(conn, ~p"/posts")

      assert posts_view.module == BlogWeb.PostsLive
      assert has_element?(posts_view, ".badge", "Blog Posts")
    end
  end

  describe "PubSub hot reload" do
    test "reloads projects when resource_reload event is received", %{conn: conn} do
      project = insert(:project, name: "Original Name", url: "https://example.com")

      {:ok, view, _html} = live(conn, ~p"/projects")

      assert render(view) =~ "Original Name"

      Blog.Projects.update_project(project, %{name: "Updated Name"})

      Phoenix.PubSub.broadcast(
        Blog.PubSub,
        "project:reload",
        {:resource_reload, Blog.Projects.Project, project.id}
      )

      _ = :sys.get_state(view.pid)

      assert render(view) =~ "Updated Name"
      refute render(view) =~ "Original Name"
    end
  end

  describe "search functionality" do
    test "renders search input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      assert has_element?(view, "input[name='q']")
      assert has_element?(view, "input[placeholder='(Web || CLI) && !Boring']")
    end

    test "updates URL when search query is entered", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      view
      |> form("form", %{"q" => "web"})
      |> render_change()

      assert_patch(view, ~p"/projects?q=web")
    end

    test "displays search results for matching query", %{conn: conn} do
      insert(:project, name: "Web Framework", url: "https://example.com", description: "A web framework")
      insert(:project, name: "CLI Tool", url: "https://example.com", description: "A CLI tool")

      {:ok, view, _html} = live(conn, ~p"/projects?q=web")

      html = render(view)
      assert html =~ "Web Framework"
      refute html =~ "CLI Tool"
    end

    test "combines search with tag filtering", %{conn: conn} do
      web_tag = insert(:tag, label: "web")
      cli_tag = insert(:tag, label: "cli")

      insert(:project, name: "Web App", url: "https://example.com", description: "Web app", tags: [web_tag])
      insert(:project, name: "CLI App", url: "https://example.com", description: "CLI app", tags: [cli_tag])
      insert(:project, name: "Both App", url: "https://example.com", description: "Web CLI app", tags: [web_tag, cli_tag])

      {:ok, view, _html} = live(conn, ~p"/projects?q=Web&tags=cli")

      html = render(view)
      assert html =~ "Both App"
      refute html =~ "Web App"
      refute html =~ "CLI App"
    end

    test "shows clear link when search query is present", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects?q=test")

      assert has_element?(view, "a[aria-label='Clear search']", "(clear ✕)")
    end

    test "clears search when clear link is clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects?q=test")

      view
      |> element("a[aria-label='Clear search']")
      |> render_click()

      assert_patch(view, ~p"/projects")
    end

    test "displays flash error for invalid FTS syntax", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      view
      |> form("form", %{"q" => "\""})
      |> render_change()

      assert render(view) =~ "Invalid search query syntax"
      assert has_element?(view, ".flash-error")
    end

    test "shows empty results on FTS error without crashing", %{conn: conn} do
      insert(:project, name: "Test Project", url: "https://example.com")

      {:ok, view, _html} = live(conn, ~p"/projects")

      view
      |> form("form", %{"q" => "\""})
      |> render_change()

      html = render(view)
      refute html =~ "Test Project"
      assert html =~ "No projects found"
    end
  end
end
