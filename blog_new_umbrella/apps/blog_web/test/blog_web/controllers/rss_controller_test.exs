defmodule BlogWeb.RssControllerTest do
  use BlogWeb.ConnCase

  import Blog.Factory

  describe "GET /rss" do
    test "returns RSS feed with correct content type", %{conn: conn} do
      conn = get(conn, ~p"/rss")
      assert response_content_type(conn, :xml) =~ "text/xml"
      assert response(conn, 200)
    end

    test "returns valid RSS XML structure", %{conn: conn} do
      post = insert(:post, title: "Test Post", slug: "test-post", is_draft: false)

      conn = get(conn, ~p"/rss")
      response_body = response(conn, 200)

      assert response_body =~ ~r/<rss version="2.0"/
      assert response_body =~ ~r/<title>Vereis' Site<\/title>/
      assert response_body =~ ~r/<description>All things Nix, Erlang, and Elixir<\/description>/
      assert response_body =~ ~r/<link>https:\/\/vereis\.com\/<\/link>/
      assert response_body =~ post.title
      assert response_body =~ post.slug
    end

    test "excludes draft posts from RSS feed", %{conn: conn} do
      published_post = insert(:post, title: "Published Post", is_draft: false)
      draft_post = insert(:post, title: "Draft Post", is_draft: true)

      conn = get(conn, ~p"/rss")
      response_body = response(conn, 200)

      assert response_body =~ published_post.title
      refute response_body =~ draft_post.title
    end

    test "includes post description in CDATA", %{conn: conn} do
      _post =
        insert(:post,
          title: "Test Post",
          description: "<p>This is a test description</p>",
          is_draft: false
        )

      conn = get(conn, ~p"/rss")
      response_body = response(conn, 200)

      assert response_body =~
               ~r/<description><!\[CDATA\[.*This is a test description.*\]\]><\/description>/s
    end

    test "includes proper publication dates", %{conn: conn} do
      published_at = ~U[2023-01-01 12:00:00Z]
      _post = insert(:post, published_at: published_at, is_draft: false)

      conn = get(conn, ~p"/rss")
      response_body = response(conn, 200)

      assert response_body =~ ~r/<pubDate>.*01 Jan 2023.*<\/pubDate>/
      assert response_body =~ ~r/<lastBuildDate>.*<\/lastBuildDate>/
    end
  end
end
