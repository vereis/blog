defmodule BlogWeb.PostsLiveTest do
  use BlogWeb.ConnCase

  import Blog.Factory
  import Phoenix.LiveViewTest

  describe ":index" do
    test "mounts successfully and displays loading state initially", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/posts")

      assert html =~ "All Posts"
      assert html =~ "posts-list"
      assert html =~ "posts-loading"
      assert html =~ "post-skeleton"
    end

    test "loads and displays posts after mount", %{conn: conn} do
      _post = insert(:post, title: "My First Post", slug: "my-first-post")

      {:ok, view, _html} = live(conn, ~p"/posts")

      assert render(view) =~ "My First Post"
      assert has_element?(view, "a[href='/posts/my-first-post']")
      refute has_element?(view, ".post-skeleton")
    end

    test "displays empty state when no posts exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      assert render(view) =~ "No posts yet. Check back soon!"
      assert has_element?(view, ".posts-list-empty")
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
      assert html =~ "~5 min"
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
      |> element("a[href='/posts/my-post']")
      |> render_click()

      assert_patch(view, ~p"/posts/my-post")
    end

    test "navigates back to home via navbar", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      {:error, {:live_redirect, %{to: path}}} =
        view
        |> element("nav ul a[href='/']", "Home")
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
      assert has_element?(projects_view, "h1", "Projects")
    end
  end

  describe "PubSub hot reload" do
    test "reloads posts when resource_reload event is received", %{conn: conn} do
      post = insert(:post, title: "Original Title", slug: "my-post")

      {:ok, view, _html} = live(conn, ~p"/posts")

      assert render(view) =~ "Original Title"

      Blog.Posts.update_post(post, %{title: "Updated Title"})

      Phoenix.PubSub.broadcast(
        Blog.PubSub,
        "post:reload",
        {:resource_reload, Blog.Posts.Post, post.id}
      )

      _ = :sys.get_state(view.pid)

      assert render(view) =~ "Updated Title"
      refute render(view) =~ "Original Title"
    end
  end
end
