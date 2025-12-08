defmodule BlogWeb.NavbarLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "navbar component" do
    test "renders semantic HTML structure", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "header")
      assert has_element?(view, "header nav")
      assert has_element?(view, "header nav ul")
    end

    test "renders all navigation links", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "a[href='/']", "Home")
      assert has_element?(view, "a[href='/posts']", "Posts")
      assert has_element?(view, "a[href='/projects']", "Projects")
    end

    test "navbar persists across page navigation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      {:ok, posts_view, _html} = view |> element("a[href='/posts']") |> render_click() |> follow_redirect(conn)

      assert has_element?(posts_view, "header nav")
      assert has_element?(posts_view, "a[href='/']", "Home")

      {:ok, projects_view, _html} =
        posts_view |> element("a[href='/projects']") |> render_click() |> follow_redirect(conn)

      assert has_element?(projects_view, "header nav")
      assert has_element?(projects_view, "a[href='/posts']", "Posts")
    end
  end
end
