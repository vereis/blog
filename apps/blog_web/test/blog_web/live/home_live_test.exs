defmodule BlogWeb.HomeLiveTest do
  use BlogWeb.ConnCase

  import Blog.Factory
  import Phoenix.LiveViewTest

  alias Blog.Posts.Post

  describe "HomeLive" do
    test "mounts successfully and displays about post", %{conn: conn} do
      insert(:post, slug: "hello-world", title: "Hello, world!")

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "article.post")
      assert has_element?(view, "#hello-world", "Hello, world!")
    end

    test "displays empty state when no about post exists", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, ".bluescreen")
      assert has_element?(view, ".bluescreen-badge", "Unexpected Error")
      assert has_element?(view, ".bluescreen-error-code")
    end

    test "subscribes to post reload events and updates when post changes", %{conn: conn} do
      post = insert(:post, slug: "hello-world", title: "Original Title")

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#hello-world", "Original Title")

      {:ok, updated_post} = Blog.Posts.update_post(post, %{title: "Updated Title"})
      Phoenix.PubSub.broadcast(Blog.PubSub, "post:reload", {:resource_reload, Post, updated_post.id})

      _ = :sys.get_state(view.pid)

      assert has_element?(view, "#hello-world", "Updated Title")
    end

    test "does not reload when a different post changes", %{conn: conn} do
      insert(:post, slug: "hello-world", title: "Hello World")
      other_post = insert(:post, slug: "other-post", title: "Other Post")

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#hello-world", "Hello World")

      {:ok, updated_other} = Blog.Posts.update_post(other_post, %{title: "Updated Other"})
      Phoenix.PubSub.broadcast(Blog.PubSub, "post:reload", {:resource_reload, Post, updated_other.id})

      _ = :sys.get_state(view.pid)

      assert has_element?(view, "#hello-world", "Hello World")
    end

    test "loads post when it gets created after initial mount", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, ".bluescreen")

      post = insert(:post, slug: "hello-world", title: "Newly Created")
      Phoenix.PubSub.broadcast(Blog.PubSub, "post:reload", {:resource_reload, Post, post.id})

      _ = :sys.get_state(view.pid)

      assert has_element?(view, "#hello-world", "Newly Created")
      refute has_element?(view, ".bluescreen")
    end

    test "empty state remains when a different post is created", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, ".bluescreen")

      other_post = insert(:post, slug: "other-post", title: "Different Post")
      Phoenix.PubSub.broadcast(Blog.PubSub, "post:reload", {:resource_reload, Post, other_post.id})

      _ = :sys.get_state(view.pid)

      assert has_element?(view, ".bluescreen")
      refute has_element?(view, "article.post")
    end

    test "renders navbar with navigation links", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "header nav")
      assert has_element?(view, "a[href='/']", "Home")
      assert has_element?(view, "a[href='/posts']", "Posts")
      assert has_element?(view, "a[href='/projects']", "Projects")
    end

    test "renders footer", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, ".site-footer")
      assert has_element?(view, ".footer-block", "RSS")
      assert has_element?(view, ".footer-block", "Source")
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

      assert has_element?(posts_view, ".badge", "Blog Posts")
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

      assert has_element?(projects_view, ".badge", "Projects")
    end
  end
end
