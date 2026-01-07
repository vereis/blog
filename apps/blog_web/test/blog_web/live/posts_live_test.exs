defmodule BlogWeb.PostsLiveTest do
  use BlogWeb.ConnCase

  import Blog.Factory
  import Phoenix.LiveViewTest

  describe ":index" do
    test "mounts successfully and displays posts list", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/posts")

      assert html =~ "Blog Posts"
    end

    test "loads and displays posts after mount", %{conn: conn} do
      _post = insert(:post, title: "My First Post", slug: "my-first-post")

      {:ok, view, _html} = live(conn, ~p"/posts")

      assert render(view) =~ "My First Post"
      assert has_element?(view, "a[href='/posts/my-first-post']")
    end

    test "displays empty state when no posts exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      assert render(view) =~ "No Posts Found"
      assert has_element?(view, ".empty-state")
    end

    test "displays posts with metadata", %{conn: conn} do
      insert(:post,
        title: "Test Post",
        slug: "test-post",
        published_at: ~U[2024-01-15 10:00:00Z],
        reading_time_minutes: 5
      )

      {:ok, view, _html} = live(conn, ~p"/posts")

      html = render(view)
      assert html =~ "Test Post"
      assert html =~ "Jan 15, 2024"
    end

    test "displays posts with index numbers", %{conn: conn} do
      insert(:post, title: "First Post", slug: "first", published_at: ~U[2024-01-20 10:00:00Z])
      insert(:post, title: "Second Post", slug: "second", published_at: ~U[2024-01-15 10:00:00Z])

      {:ok, view, _html} = live(conn, ~p"/posts")

      html = render(view)
      assert html =~ "#1"
      assert html =~ "#2"
    end

    test "renders navbar with navigation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      assert has_element?(view, "header nav")
      assert has_element?(view, "a[href='/']", "Home")
      assert has_element?(view, "a[href='/projects']", "Projects")
    end

    test "sets page title to Posts", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      assert page_title(view) =~ "Posts"
    end

    test "navigates to individual post via patch", %{conn: conn} do
      insert(:post, title: "My Post", slug: "my-post")

      {:ok, view, _html} = live(conn, ~p"/posts")

      render(view)

      view
      |> element(".post-title a[href='/posts/my-post']")
      |> render_click()

      assert_patch(view, ~p"/posts/my-post")
    end

    test "navigates back to home via navbar", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      {:error, {:live_redirect, %{to: path}}} =
        view
        |> element("nav.site-nav a[href='/']", "Home")
        |> render_click()

      assert path == ~p"/"
    end
  end

  describe ":show" do
    test "displays post when found", %{conn: conn} do
      _post =
        insert(:post,
          title: "My Awesome Post",
          slug: "my-awesome-post",
          body: "<p>Post content here</p>"
        )

      {:ok, view, html} = live(conn, ~p"/posts/my-awesome-post")

      assert html =~ "My Awesome Post"
      assert html =~ "Post content here"
      assert has_element?(view, ".post")
    end

    test "displays bluescreen for non-existent post", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/posts/non-existent")

      assert html =~ "Unexpected Error"
      assert html =~ "Error:"
      assert has_element?(view, ".bluescreen")
      assert has_element?(view, "a[href='/posts']")
    end

    test "sets page title to post title when found", %{conn: conn} do
      insert(:post, title: "My Post Title", slug: "my-post")

      {:ok, view, _html} = live(conn, ~p"/posts/my-post")

      assert page_title(view) =~ "My Post Title"
    end

    test "sets page title to 'Post Not Found' when not found", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/missing")

      assert page_title(view) =~ "Post Not Found"
    end

    test "displays post metadata", %{conn: conn} do
      insert(:post,
        title: "Test Post",
        slug: "test-post",
        published_at: ~U[2024-01-15 10:00:00Z],
        reading_time_minutes: 5
      )

      {:ok, _view, html} = live(conn, ~p"/posts/test-post")

      assert html =~ "January 15, 2024"
      assert html =~ "Approx. 5 minutes read"
    end

    test "different slugs render different posts", %{conn: conn} do
      insert(:post, title: "First Post", slug: "first-post", body: "<p>First content</p>")
      insert(:post, title: "Second Post", slug: "second-post", body: "<p>Second content</p>")

      {:ok, _view1, html1} = live(conn, ~p"/posts/first-post")
      assert html1 =~ "First Post"
      assert html1 =~ "First content"

      {:ok, _view2, html2} = live(conn, ~p"/posts/second-post")
      assert html2 =~ "Second Post"
      assert html2 =~ "Second content"
    end

    test "displays table of contents when post has multiple headings", %{conn: conn} do
      insert(:post,
        title: "Test Post",
        slug: "test-post",
        body: "<p>Content</p>",
        headings: [
          %{title: "Test Post", link: "test-post", level: 1},
          %{title: "Introduction", link: "introduction", level: 2},
          %{title: "Conclusion", link: "conclusion", level: 2}
        ]
      )

      {:ok, view, html} = live(conn, ~p"/posts/test-post")

      assert html =~ ~s(class="toc")
      assert has_element?(view, ".page-aside .toc")
      assert has_element?(view, "a[href='#introduction']")
      assert has_element?(view, "a[href='#conclusion']")
    end

    test "displays TOC empty state when post has only title heading", %{conn: conn} do
      insert(:post,
        title: "Test Post",
        slug: "test-post",
        body: "<p>Content</p>",
        headings: [
          %{title: "Test Post", link: "test-post", level: 1}
        ]
      )

      {:ok, view, html} = live(conn, ~p"/posts/test-post")

      assert html =~ ~s(class="toc")
      assert has_element?(view, ".toc-empty", "No headings available")
      assert has_element?(view, ".page-aside .discord-presence")
    end
  end

  describe "cross-LiveView navigation" do
    test "navigates to projects from posts", %{conn: conn} do
      {:ok, posts_view, _html} = live(conn, ~p"/posts")

      {:error, {:live_redirect, %{to: path}}} =
        posts_view
        |> element("a[href='/projects']", "Projects")
        |> render_click()

      assert path == ~p"/projects"
    end

    test "navigates to projects and renders correctly", %{conn: conn} do
      {:ok, posts_view, _html} = live(conn, ~p"/posts")

      {:ok, projects_view, _html} =
        posts_view
        |> element("a[href='/projects']", "Projects")
        |> render_click()
        |> follow_redirect(conn, ~p"/projects")

      assert projects_view.module == BlogWeb.ProjectsLive
      assert has_element?(projects_view, ".badge", "Projects")
    end
  end

  describe "PubSub hot reload" do
    test "reloads posts when content_imported event is received", %{conn: conn} do
      post = insert(:post, title: "Original Title", slug: "my-post")

      {:ok, view, _html} = live(conn, ~p"/posts")

      assert render(view) =~ "Original Title"

      Blog.Posts.update_post(post, %{title: "Updated Title"})

      Phoenix.PubSub.broadcast(
        Blog.PubSub,
        Blog.Content.pubsub_topic(),
        {:content_imported}
      )

      _ = :sys.get_state(view.pid)

      assert render(view) =~ "Updated Title"
      refute render(view) =~ "Original Title"
    end
  end

  describe "search functionality" do
    test "renders search input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      assert has_element?(view, "input[name='q']")
      assert has_element?(view, "input[placeholder='(Distributed && Elixir) || Fun']")
    end

    test "updates URL when search query is entered", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      view
      |> form("form", %{"q" => "elixir"})
      |> render_change()

      assert_patch(view, ~p"/posts?q=elixir")
    end

    test "displays search results for matching query", %{conn: conn} do
      insert(:post, title: "Elixir is great", slug: "elixir-post", raw_body: "Elixir content")
      insert(:post, title: "Phoenix framework", slug: "phoenix-post", raw_body: "Phoenix content")

      {:ok, view, _html} = live(conn, ~p"/posts?q=Elixir")

      html = render(view)
      assert html =~ "Elixir is great"
      refute html =~ "Phoenix framework"
    end

    test "combines search with tag filtering", %{conn: conn} do
      elixir_tag = insert(:tag, label: "elixir")
      phoenix_tag = insert(:tag, label: "phoenix")

      insert(:post, title: "Elixir Post", slug: "elixir-post", raw_body: "Elixir", tags: [elixir_tag])
      insert(:post, title: "Phoenix Post", slug: "phoenix-post", raw_body: "Phoenix", tags: [phoenix_tag])
      insert(:post, title: "Elixir Phoenix", slug: "both", raw_body: "Both", tags: [elixir_tag, phoenix_tag])

      {:ok, view, _html} = live(conn, ~p"/posts?q=Elixir&tags=phoenix")

      html = render(view)
      assert html =~ "Elixir Phoenix"
      refute html =~ "Elixir Post"
      refute html =~ "Phoenix Post"
    end

    test "shows clear link when search query is present", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts?q=test")

      assert has_element?(view, "a[aria-label='Clear search']", "(clear ✕)")
    end

    test "clears search when clear link is clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts?q=test")

      view
      |> element("a[aria-label='Clear search']")
      |> render_click()

      assert_patch(view, ~p"/posts")
    end

    test "displays flash error for invalid FTS syntax", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      view
      |> form("form", %{"q" => "\""})
      |> render_change()

      assert render(view) =~ "Invalid search query syntax"
      assert has_element?(view, ".flash-error")
    end

    test "shows empty results on FTS error without crashing", %{conn: conn} do
      insert(:post, title: "Test Post", slug: "test")

      {:ok, view, _html} = live(conn, ~p"/posts")

      view
      |> form("form", %{"q" => "\""})
      |> render_change()

      html = render(view)
      refute html =~ "Test Post"
      assert html =~ "No Posts Found"
    end
  end
end
