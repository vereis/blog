defmodule BlogWeb.PostsLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest

  describe ":index" do
    test "mounts successfully and displays content", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      assert has_element?(view, "h1", "Posts")
      assert has_element?(view, "p", "All blog posts will be listed here")
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

    test "navigates back to home via navbar (live_redirect)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      {:error, {:live_redirect, %{to: path}}} =
        view
        |> element("nav ul a[href='/']", "Home")
        |> render_click()

      assert path == ~p"/"
    end

    test "navigates back to home and renders home page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts")

      {:ok, home_view, _html} =
        view
        |> element("nav ul a[href='/']", "Home")
        |> render_click()
        |> follow_redirect(conn, ~p"/")

      assert home_view.module == BlogWeb.HomeLive
    end
  end

  describe ":show" do
    test "mounts successfully with slug and displays content", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/my-awesome-post")

      assert has_element?(view, "h1", "Post: my-awesome-post")
      assert has_element?(view, "p", "Individual post content will be rendered here")
    end

    test "sets page title to post slug", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/my-awesome-post")

      assert page_title(view) =~ "Post: my-awesome-post"
    end

    test "different slugs render different content", %{conn: conn} do
      {:ok, view1, _html} = live(conn, ~p"/posts/first-post")
      assert has_element?(view1, "h1", "Post: first-post")

      {:ok, view2, _html} = live(conn, ~p"/posts/second-post")
      assert has_element?(view2, "h1", "Post: second-post")
    end
  end

  describe "cross-LiveView navigation" do
    test "navigates to projects from posts (live_redirect)", %{conn: conn} do
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
end
