defmodule BlogWeb.PageControllerTest do
  use BlogWeb.ConnCase

  import Blog.Factory

  # The root route now goes to BlogLive instead of PageController
  # So we test that the LiveView is rendered properly
  test "GET / redirects to BlogLive", %{conn: conn} do
    # Create a default post so the LiveView doesn't fail
    insert(:post, slug: "hello_world", title: "Welcome")

    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "root@vereis.com"
  end
end
