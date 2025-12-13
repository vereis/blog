defmodule BlogWeb.Components.PostTest do
  use BlogWeb.ConnCase

  import Blog.Factory
  import Phoenix.LiveViewTest

  alias Blog.Tags.Tag
  alias BlogWeb.Components.Post

  describe "Post.list/1 - empty state" do
    test "renders empty state message when empty is true" do
      html = render_component(&Post.list/1, %{posts: []})

      assert html =~ ~s(class="posts-list-empty")
      assert html =~ "No posts yet. Check back soon!"
    end

    test "renders list structure for empty state" do
      html = render_component(&Post.list/1, %{posts: []})

      assert html =~ "<ol"
      assert html =~ "posts-list"
    end
  end

  describe "Post.list/1 - with title" do
    test "renders default title badge 'Blog Posts'" do
      html = render_component(&Post.list/1, %{posts: []})

      assert html =~ "Blog Posts"
      assert html =~ "badge"
    end

    test "renders custom title badge when provided" do
      html = render_component(&Post.list/1, %{posts: [], title: "Recent Posts"})

      assert html =~ "Recent Posts"
      assert html =~ "badge"
      refute html =~ "Blog Posts"
    end
  end

  describe "Post.list/1 - with posts" do
    setup do
      posts = [
        build(:post,
          id: 1,
          title: "First Post",
          slug: "first-post",
          published_at: ~U[2024-01-15 10:00:00Z],
          reading_time_minutes: 5,
          tags: [
            %Tag{id: 1, label: "elixir"},
            %Tag{id: 2, label: "phoenix"}
          ]
        ),
        build(:post,
          id: 2,
          title: "Second Post",
          slug: "second-post",
          published_at: ~U[2024-01-20 14:00:00Z],
          reading_time_minutes: 3,
          tags: [%Tag{id: 3, label: "testing"}]
        )
      ]

      %{posts: posts}
    end

    test "renders all posts in the list", %{posts: posts} do
      html = render_component(&Post.list/1, %{posts: posts})

      assert html =~ "First Post"
      assert html =~ "Second Post"
    end

    test "renders posts with correct index numbers", %{posts: posts} do
      html = render_component(&Post.list/1, %{posts: posts})

      assert html =~ ~s(<span class="post-index">#1</span>)
      assert html =~ ~s(<span class="post-index">#2</span>)
    end

    test "renders post metadata (date)", %{posts: posts} do
      html = render_component(&Post.list/1, %{posts: posts})

      assert html =~ "Jan 15, 2024"
      assert html =~ "Jan 20, 2024"
    end

    test "renders links to individual posts", %{posts: posts} do
      html = render_component(&Post.list/1, %{posts: posts})

      assert html =~ ~s(href="/posts/first-post")
      assert html =~ ~s(href="/posts/second-post")
      assert html =~ ~s(data-phx-link="patch")
    end

    test "includes aria-label on links for accessibility", %{posts: posts} do
      html = render_component(&Post.list/1, %{posts: posts})

      assert html =~ ~s(aria-label="Read post: First Post")
      assert html =~ ~s(aria-label="Read post: Second Post")
    end

    test "renders post tags", %{posts: posts} do
      html = render_component(&Post.list/1, %{posts: posts})

      assert html =~ "elixir"
      assert html =~ "phoenix"
      assert html =~ "testing"
    end

    test "renders semantic HTML structure", %{posts: posts} do
      html = render_component(&Post.list/1, %{posts: posts})

      assert html =~ "<ol"
      assert html =~ "posts-list"
      assert html =~ "<li"
      assert html =~ "post-item"
      assert html =~ "<article>"
      assert html =~ "<h2"
      assert html =~ "<time"
    end

    test "includes proper datetime attributes on time elements", %{posts: posts} do
      html = render_component(&Post.list/1, %{posts: posts})

      assert html =~ ~s(datetime="2024-01-15T10:00:00Z")
      assert html =~ ~s(datetime="2024-01-20T14:00:00Z")
    end

    test "assigns correct DOM IDs to list items", %{posts: posts} do
      html = render_component(&Post.list/1, %{posts: posts})

      assert html =~ ~s(id="post-1")
      assert html =~ ~s(id="post-2")
    end

    test "accepts custom id attribute for the list", %{posts: posts} do
      html = render_component(&Post.list/1, %{posts: posts, id: "custom-posts"})

      assert html =~ ~s(id="custom-posts")
    end

    test "accepts rest attributes for additional HTML attributes", %{posts: posts} do
      html =
        render_component(&Post.list/1, %{
          posts: posts,
          empty: false,
          "data-test": "posts-list"
        })

      assert html =~ ~s(data-test="posts-list")
    end
  end
end
