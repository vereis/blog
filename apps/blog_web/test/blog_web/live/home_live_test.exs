defmodule BlogWeb.HomeLiveTest do
  use BlogWeb.ConnCase

  import Blog.Factory
  import Phoenix.LiveViewTest

  alias Blog.Posts.Post

  describe "HomeLive" do
    test "mounts successfully and displays about post", %{conn: conn} do
      insert(:post, slug: "hello-world", title: "Hello, world!")

      {:ok, view, _html} = live(conn, ~p"/")
      html = render_async(view)

      assert html =~ "Hello, world!"
      assert has_element?(view, "article.post")
      assert has_element?(view, "h1#hello-world", "Hello, world!")
    end

    test "displays empty state when no about post exists", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      render_async(view)

      assert has_element?(view, ".empty")
      assert has_element?(view, ".empty span", "No content available yet")
    end

    test "subscribes to post reload events and updates when post changes", %{conn: conn} do
      post = insert(:post, slug: "hello-world", title: "Original Title")

      {:ok, view, _html} = live(conn, ~p"/")
      render_async(view)

      assert has_element?(view, "h1#hello-world", "Original Title")

      {:ok, updated_post} = Blog.Posts.update_post(post, %{title: "Updated Title"})
      Phoenix.PubSub.broadcast(Blog.PubSub, "post:reload", {:resource_reload, Post, updated_post.id})

      render_async(view)

      assert has_element?(view, "h1#hello-world", "Updated Title")
    end

    test "does not reload when a different post changes", %{conn: conn} do
      insert(:post, slug: "hello-world", title: "Hello World")
      other_post = insert(:post, slug: "other-post", title: "Other Post")

      {:ok, view, _html} = live(conn, ~p"/")
      render_async(view)

      assert has_element?(view, "h1#hello-world", "Hello World")

      {:ok, updated_other} = Blog.Posts.update_post(other_post, %{title: "Updated Other"})
      Phoenix.PubSub.broadcast(Blog.PubSub, "post:reload", {:resource_reload, Post, updated_other.id})

      assert has_element?(view, "h1#hello-world", "Hello World")
    end

    test "renders navbar with navigation links", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "header nav")
      assert has_element?(view, "a[href='/']", "Home")
      assert has_element?(view, "a[href='/posts']", "Posts")
      assert has_element?(view, "a[href='/projects']", "Projects")
    end

    test "renders footer with current year", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      current_year = Date.utc_today().year
      assert has_element?(view, "footer p", "© #{current_year} vereis")
    end
  end

  describe "navigation to other LiveViews" do
    test "navigates to posts when clicking Posts link (live_redirect)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      {:error, {:live_redirect, %{to: path}}} =
        view
        |> element("a[href='/posts']", "Posts")
        |> render_click()

      assert path == ~p"/posts"
    end

    test "navigates to posts and renders posts page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      {:ok, posts_view, _html} =
        view
        |> element("a[href='/posts']", "Posts")
        |> render_click()
        |> follow_redirect(conn, ~p"/posts")

      assert has_element?(posts_view, "h1", "Posts")
      assert has_element?(posts_view, "p", "All blog posts will be listed here")
    end

    test "navigates to projects when clicking Projects link", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      {:error, {:live_redirect, %{to: path}}} =
        view
        |> element("a[href='/projects']", "Projects")
        |> render_click()

      assert path == ~p"/projects"
    end

    test "navigates to projects and renders projects page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      {:ok, projects_view, _html} =
        view
        |> element("a[href='/projects']", "Projects")
        |> render_click()
        |> follow_redirect(conn, ~p"/projects")

      assert has_element?(projects_view, "h1", "Projects")
      assert has_element?(projects_view, "p", "All projects will be listed here")
    end
  end
end
