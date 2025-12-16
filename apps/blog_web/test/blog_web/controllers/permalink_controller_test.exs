defmodule BlogWeb.PermalinkControllerTest do
  use BlogWeb.ConnCase

  import Blog.Factory

  describe "GET /:permalink" do
    test "redirects to post when permalink exists", %{conn: conn} do
      _post = insert(:post, slug: "my-post", permalinks: ["short-link"])

      conn = get(conn, "/short-link")

      assert redirected_to(conn, 302) == ~p"/posts/my-post"
    end

    test "redirects to post with first matching permalink", %{conn: conn} do
      _post = insert(:post, slug: "my-post", permalinks: ["alias1", "alias2", "alias3"])

      conn1 = get(conn, "/alias1")
      assert redirected_to(conn1, 302) == ~p"/posts/my-post"

      conn2 = get(conn, "/alias2")
      assert redirected_to(conn2, 302) == ~p"/posts/my-post"

      conn3 = get(conn, "/alias3")
      assert redirected_to(conn3, 302) == ~p"/posts/my-post"
    end

    test "redirects to home with flash when permalink not found", %{conn: conn} do
      conn = get(conn, "/nonexistent-permalink")

      assert redirected_to(conn, 302) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               {"Page Not Found", "The page you're looking for doesn't exist."}
    end

    test "redirects to home with flash for draft posts", %{conn: conn} do
      insert(:post, slug: "draft-post", permalinks: ["draft-link"], is_draft: true)

      conn = get(conn, "/draft-link")

      assert redirected_to(conn, 302) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               {"Page Not Found", "The page you're looking for doesn't exist."}
    end

    test "handles posts with empty permalinks array", %{conn: conn} do
      insert(:post, slug: "no-permalinks", permalinks: [])

      conn = get(conn, "/no-permalinks")

      assert redirected_to(conn, 302) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               {"Page Not Found", "The page you're looking for doesn't exist."}
    end

    test "handles posts with nil permalinks", %{conn: conn} do
      post = insert(:post, slug: "nil-permalinks")
      # Explicitly set permalinks to nil in the database
      Blog.Repo.update!(Ecto.Changeset.change(post, permalinks: nil))

      conn = get(conn, "/nil-permalinks")

      assert redirected_to(conn, 302) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               {"Page Not Found", "The page you're looking for doesn't exist."}
    end
  end
end
