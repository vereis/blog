defmodule BlogWeb.RssControllerTest do
  use BlogWeb.ConnCase

  import Blog.Factory

  describe "GET /rss" do
    test "returns RSS feed with correct content type", %{conn: conn} do
      conn = get(conn, ~p"/rss")
      assert response_content_type(conn, :xml) =~ "application/rss+xml"
      assert response(conn, 200)
    end

    test "returns valid RSS 2.0 XML structure", %{conn: conn} do
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

    test "includes post excerpt in CDATA", %{conn: conn} do
      _post =
        insert(:post,
          title: "Test Post",
          excerpt: "<p>This is a test excerpt</p>",
          is_draft: false
        )

      conn = get(conn, ~p"/rss")
      response_body = response(conn, 200)

      assert response_body =~
               ~r/<description><!\[CDATA\[.*This is a test excerpt.*\]\]><\/description>/s
    end

    test "includes proper RFC822 publication dates", %{conn: conn} do
      published_at = ~U[2023-01-01 12:00:00Z]
      _post = insert(:post, published_at: published_at, is_draft: false)

      conn = get(conn, ~p"/rss")
      response_body = response(conn, 200)

      assert response_body =~ ~r/<pubDate>.*01 Jan 2023.*<\/pubDate>/
      assert response_body =~ ~r/<lastBuildDate>.*<\/lastBuildDate>/
    end

    test "handles posts with special characters in title", %{conn: conn} do
      _post =
        insert(:post,
          title: "Test & <Special> \"Characters\"",
          is_draft: false
        )

      conn = get(conn, ~p"/rss")
      response_body = response(conn, 200)

      # XML should be properly escaped
      assert response_body =~ "Test &amp; &lt;Special&gt;"
    end

    test "orders posts by published_at descending", %{conn: conn} do
      post1 = insert(:post, title: "Older Post", published_at: ~U[2023-01-01 12:00:00Z], is_draft: false)
      post2 = insert(:post, title: "Newer Post", published_at: ~U[2023-01-02 12:00:00Z], is_draft: false)

      conn = get(conn, ~p"/rss")
      response_body = response(conn, 200)

      # Newer post should appear before older post in the feed
      newer_pos = response_body |> :binary.match(post2.title) |> elem(0)
      older_pos = response_body |> :binary.match(post1.title) |> elem(0)

      assert newer_pos < older_pos
    end

    test "handles empty feed gracefully", %{conn: conn} do
      conn = get(conn, ~p"/rss")
      response_body = response(conn, 200)

      assert response_body =~ ~r/<rss version="2.0"/
      assert response_body =~ ~r/<channel>/
      assert response_body =~ ~r/<\/channel>/
    end

    test "includes Read more link in excerpt", %{conn: conn} do
      _post =
        insert(:post,
          title: "Test Post",
          excerpt: "<p>This is a test excerpt</p>",
          is_draft: false
        )

      conn = get(conn, ~p"/rss")
      response_body = response(conn, 200)

      assert response_body =~ "Read more"
    end
  end
end
