defmodule BlogWeb.Components.FooterTest do
  use BlogWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Footer.footer/1" do
    test "renders footer with vim-style blocks", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, ".site-footer")
      assert has_element?(view, ".footer-block", "RSS")
      assert has_element?(view, ".footer-block", "Source")
    end

    test "footer includes RSS link on left", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "a.footer-block[href='/rss']", "RSS")
    end

    test "footer includes source code link on right", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "a.footer-block[href='https://github.com/vereis/blog']", "Source")
    end

    test "source link opens in new tab with security attributes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "a.footer-block[target='_blank'][rel='noopener noreferrer']", "Source")
      assert has_element?(view, "a.footer-block[aria-label='Source code (opens in new tab)']")
    end

    test "footer persists across page navigation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      {:ok, posts_view, _html} =
        view |> element("a[href='/posts']") |> render_click() |> follow_redirect(conn)

      assert has_element?(posts_view, ".site-footer")
      assert has_element?(posts_view, ".footer-block", "RSS")
      assert has_element?(posts_view, ".footer-block", "Source")
    end
  end
end
