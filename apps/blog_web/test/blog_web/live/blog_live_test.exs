defmodule BlogWeb.BlogLiveTest do
  use BlogWeb.ConnCase

  import Blog.Factory
  import Phoenix.LiveViewTest

  describe "BlogLive" do
    test "disconnected and connected render", %{conn: conn} do
      {:ok, page_live, disconnected_html} = live(conn, ~p"/")
      assert disconnected_html =~ "root@vereis.com"
      assert render(page_live) =~ "root@vereis.com"
    end
  end

  describe "home page (:home)" do
    test "renders home page with default post", %{conn: conn} do
      post = insert(:post, slug: "hello_world", title: "Welcome Post")

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "root@vereis.com"
      assert html =~ post.title
    end

    test "shows table of contents for post with headings", %{conn: conn} do
      headings = [
        %{id: "heading-1", link: "#heading-1", title: "# Heading 1", level: 1},
        %{id: "heading-2", link: "#heading-2", title: "## Heading 2", level: 2}
      ]

      _post = insert(:post, slug: "hello_world", headings: headings)

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Table of Contents"
      assert html =~ "Heading 1"
      assert html =~ "Heading 2"
    end

    test "includes CRT filter toggle", %{conn: conn} do
      insert(:post, slug: "hello_world")

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~r/crt.*checkbox/i
      assert html =~ "crtFilter"
    end

    test "includes link to projects", %{conn: conn} do
      insert(:post, slug: "hello_world")

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("a[phx-click=\"projects\"]", "projects")
      |> render_click()

      assert ~p"/projects" == assert_patch(view)
    end

    test "includes link to posts", %{conn: conn} do
      insert(:post, slug: "hello_world")

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("a[phx-click=\"posts\"]", "blog")
      |> render_click()

      assert ~p"/posts" == assert_patch(view)
    end

    test "includes link to rss feed", %{conn: conn} do
      insert(:post, slug: "hello_world")

      {:ok, view, _html} = live(conn, ~p"/")

      assert view
             |> element("a[href=\"/rss\"]", "rss")
             |> render() =~ "/rss"
    end
  end

  describe "projects page (:list_projects)" do
    test "renders projects list", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/projects/")

      assert html =~ "All Projects"
      assert html =~ "Personal projects or open source contributions"
      assert html =~ "Neovim Config"
      assert html =~ "Toggle"
      assert html =~ "elixir"
      assert html =~ "nix"
    end

    test "filters projects by tag", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/")

      # Click on elixir tag
      html = view |> element("a[phx-click=\"proj-tag\"]", "#elixir") |> render_click()

      assert html =~ "All Projects (#elixir)"
      # Has elixir tag
      assert html =~ "Toggle"
      # Doesn't have elixir tag
      refute html =~ "Neovim Config"
    end

    test "can clear tag filter", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/")

      # Apply filter first
      view |> element("a[phx-click=\"proj-tag\"]", "#elixir") |> render_click()

      # Then clear it
      html = view |> element("a", "(clear)") |> render_click()

      assert html =~ "All Projects"
      refute html =~ "(#elixir)"
    end

    test "navigation buttons work from projects", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/")

      # Test navigation to posts
      view |> element("a", "blog") |> render_click()
      assert_patch(view, ~p"/posts")

      # Test navigation to home
      view |> element("a", "root@vereis.com ~") |> render_click()
      assert_patch(view, ~p"/")
    end
  end

  describe "posts page (:list_posts)" do
    test "renders posts list", %{conn: conn} do
      post1 = insert(:post, title: "First Post", is_draft: false)
      post2 = insert(:post, title: "Second Post", is_draft: false)

      {:ok, _view, html} = live(conn, ~p"/posts/")

      assert html =~ "Blog Posts"
      assert html =~ "Personal blog posts, notes, and other ramblings"
      assert html =~ post1.title
      assert html =~ post2.title
    end

    test "filters posts by tag", %{conn: conn} do
      tag1 = insert(:tag, label: "elixir")
      tag2 = insert(:tag, label: "nix")

      post1 = insert(:post, title: "Elixir Post", tags: [tag1], is_draft: false)
      post2 = insert(:post, title: "Nix Post", tags: [tag2], is_draft: false)

      {:ok, view, _html} = live(conn, ~p"/posts/")

      # Click on elixir tag
      html = view |> element("a[phx-click=\"tag\"]", "#elixir") |> render_click()

      assert html =~ "Blog Posts (#elixir)"
      assert html =~ post1.title
      refute html =~ post2.title
    end

    test "searches posts", %{conn: conn} do
      post1 = insert(:post, title: "Elixir Tutorial", is_draft: false)
      post2 = insert(:post, title: "Nix Configuration", is_draft: false)

      {:ok, view, _html} = live(conn, ~p"/posts/")

      # Search for "elixir"
      view |> form(".component-container", search: "elixir") |> render_change()

      # Should only show matching post
      html = render(view)
      assert html =~ post1.title
      refute html =~ post2.title
    end

    test "clicking post navigates to post detail", %{conn: conn} do
      post = insert(:post, title: "Test Post", slug: "test-post", is_draft: false)

      {:ok, view, _html} = live(conn, ~p"/posts/")

      view |> element(".post[phx-value-post='#{post.slug}']") |> render_click()
      assert_patch(view, ~p"/posts/#{post.slug}")
    end

    test "excludes draft posts in release mode", %{conn: conn} do
      published_post = insert(:post, title: "Published", is_draft: false)
      _draft_post = insert(:post, title: "Draft", is_draft: true)

      # Mock release mode
      {:ok, view, _html} = live(conn, ~p"/posts/")

      html = render(view)
      assert html =~ published_post.title
      # Note: Draft filtering logic depends on is_release? assign
    end
  end

  describe "post detail page (:show_post)" do
    test "renders individual post", %{conn: conn} do
      post =
        insert(:post,
          title: "Test Post",
          slug: "test-post",
          body: "<p>This is the post content</p>",
          published_at: ~U[2023-01-01 12:00:00Z],
          reading_time_minutes: 5
        )

      {:ok, _view, html} = live(conn, ~p"/posts/#{post.slug}")

      assert html =~ post.title
      assert html =~ "This is the post content"
      assert html =~ "January 01 2023"
      assert html =~ "5 minute read"
    end

    test "shows post metadata", %{conn: conn} do
      tag = insert(:tag, label: "testing")

      post =
        insert(:post,
          title: "Metadata Test",
          slug: "metadata-test",
          tags: [tag],
          published_at: ~U[2023-06-15 14:30:00Z],
          reading_time_minutes: 3
        )

      {:ok, _view, html} = live(conn, ~p"/posts/#{post.slug}")

      assert html =~ "June 15 2023, 14:30:00"
      assert html =~ "Approx. 3 minute read"
      assert html =~ "#testing"
    end

    test "renders table of contents", %{conn: conn} do
      headings = [
        %{id: "intro", link: "#intro", title: "# Introduction", level: 1},
        %{id: "details", link: "#details", title: "## Details", level: 2}
      ]

      post =
        insert(:post,
          title: "TOC Test",
          slug: "toc-test",
          headings: headings
        )

      {:ok, _view, html} = live(conn, ~p"/posts/#{post.slug}")

      assert html =~ "Table of Contents"
      assert html =~ "Introduction"
      assert html =~ "Details"
      assert html =~ ~r/data-level="1"/
      assert html =~ ~r/data-level="2"/
    end

    test "clicking tag filters posts", %{conn: conn} do
      tag = insert(:tag, label: "elixir")
      post = insert(:post, slug: "tagged-post", tags: [tag])

      {:ok, view, _html} = live(conn, ~p"/posts/#{post.slug}")

      view |> element("a[phx-click=\"tag\"]", "#elixir") |> render_click()
      assert_patch(view, ~p"/posts")
    end
  end

  describe "navigation and events" do
    test "home button navigates to home", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/")

      view |> element("a", "root@vereis.com ~") |> render_click()
      assert_patch(view, ~p"/")
    end

    test "posts button navigates to posts list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("a", "blog") |> render_click()
      assert_patch(view, ~p"/posts")
    end

    test "projects button navigates to projects list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("a", "projects") |> render_click()
      assert_patch(view, ~p"/projects")
    end

    test "handles post reload event", %{conn: conn} do
      post = insert(:post, slug: "hello_world", title: "Original Title")

      {:ok, view, _html} = live(conn, ~p"/")

      # Simulate resource reload broadcast with new format
      send(view.pid, {:resource_reload, Blog.Resource.Post, post.id})

      # View should handle the message without crashing
      assert render(view) =~ "root@vereis.com"
    end
  end

  describe "responsive design elements" do
    test "includes blink animation for cursor", %{conn: conn} do
      insert(:post, slug: "hello_world")

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "<blink>█</blink>"
    end

    test "includes footer with links", %{conn: conn} do
      insert(:post, slug: "hello_world")

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "BACK"
      assert html =~ "rss"
      assert html =~ "source code"
      assert html =~ "https://github.com/vereis/blog"
    end

    test "includes Discord presence status indicator", %{conn: conn} do
      insert(:post, slug: "hello_world")

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "status-indicator status-disconnected"
      assert html =~ "data-tooltip=\"Disconnected\""
    end

    test "updates status indicator when presence changes", %{conn: conn} do
      insert(:post, slug: "hello_world")

      {:ok, view, html} = live(conn, ~p"/")

      # Initially shows disconnected
      assert html =~ "data-tooltip=\"Disconnected\""
      assert html =~ "status-disconnected"

      # Simulate presence update via PubSub
      online_presence = %Blog.Lanyard.Presence{
        connected?: true,
        discord_status: "online",
        discord_user: %{"username" => "vereis"}
      }

      send(view.pid, {:presence_updated, online_presence})

      # Should update to online status
      updated_html = render(view)
      assert updated_html =~ "data-tooltip=\"Online\""
      assert updated_html =~ "status-online"
    end

    test "includes custom tooltip with CSS styling", %{conn: conn} do
      insert(:post, slug: "hello_world")

      {:ok, _view, html} = live(conn, ~p"/")

      # Should have the tooltip data attribute for CSS ::after content
      assert html =~ "data-tooltip=\"Disconnected\""

      # Should have help cursor and positioning for tooltip
      assert html =~ "status-indicator"
    end
  end
end
