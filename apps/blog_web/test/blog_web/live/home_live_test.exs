defmodule BlogWeb.HomeLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "HomeLive" do
    test "mounts successfully and displays content", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "h1", "Home")
      assert has_element?(view, "p", "Welcome to the blog!")
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
