defmodule BlogWeb.RedirectControllerTest do
  use BlogWeb.ConnCase

  describe "GET /minna-chat" do
    test "redirects to Discord invite", %{conn: conn} do
      conn = get(conn, ~p"/minna-chat")
      assert redirected_to(conn) == "https://discord.gg/WGGhk5wjYT"
      assert response(conn, 302)
    end

    test "does not use any layout", %{conn: conn} do
      conn = get(conn, ~p"/minna-chat")
      # Verify no layout is rendered by checking the response is a simple redirect
      assert get_resp_header(conn, "location") == ["https://discord.gg/WGGhk5wjYT"]
    end
  end

  describe "GET /uses" do
    test "redirects to /posts/uses", %{conn: conn} do
      conn = get(conn, ~p"/uses")
      assert redirected_to(conn) == "/posts/uses"
      assert response(conn, 302)
    end

    test "uses internal redirect", %{conn: conn} do
      conn = get(conn, ~p"/uses")
      # Verify it's an internal redirect (not external)
      location = conn |> get_resp_header("location") |> List.first()
      refute String.starts_with?(location, "http")
    end
  end
end
