defmodule BlogWeb.ProjectsLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest

  describe ":index" do
    test "mounts successfully and displays content", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      assert has_element?(view, "h1", "Projects")
      assert has_element?(view, "p", "All projects will be listed here")
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

    test "navigates back to home via navbar (live_redirect)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      {:error, {:live_redirect, %{to: path}}} =
        view
        |> element("nav ul a[href='/']", "Home")
        |> render_click()

      assert path == ~p"/"
    end

    test "navigates back to home and renders home page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      {:ok, home_view, _html} =
        view
        |> element("nav ul a[href='/']", "Home")
        |> render_click()
        |> follow_redirect(conn, ~p"/")

      assert home_view.module == BlogWeb.HomeLive
    end

    test "navigates to posts via navbar (live_redirect)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      {:error, {:live_redirect, %{to: path}}} =
        view
        |> element("a[href='/posts']", "Posts")
        |> render_click()

      assert path == ~p"/posts"
    end

    test "navigates to posts and renders posts page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects")

      {:ok, posts_view, _html} =
        view
        |> element("a[href='/posts']", "Posts")
        |> render_click()
        |> follow_redirect(conn, ~p"/posts")

      assert has_element?(posts_view, ".badge", "All Posts")
    end
  end
end
