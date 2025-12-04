defmodule Blog.PostsTest do
  use Blog.DataCase, async: true

  alias Blog.Posts

  describe "list_posts/1" do
    test "returns all posts" do
      post1 = insert(:post, title: "First", slug: "first")
      post2 = insert(:post, title: "Second", slug: "second")

      posts = Posts.list_posts()

      assert length(posts) == 2
      assert Enum.any?(posts, &(&1.id == post1.id))
      assert Enum.any?(posts, &(&1.id == post2.id))
    end

    test "returns empty list when no posts exist" do
      assert Posts.list_posts() == []
    end

    test "filters posts by is_draft" do
      draft_post = insert(:post, slug: "draft", is_draft: true)
      published_post = insert(:post, slug: "published", is_draft: false)

      drafts = Posts.list_posts(is_draft: true)
      published = Posts.list_posts(is_draft: false)

      assert length(drafts) == 1
      assert hd(drafts).id == draft_post.id

      assert length(published) == 1
      assert hd(published).id == published_post.id
    end

    test "limits results" do
      insert(:post, slug: "post-1")
      insert(:post, slug: "post-2")
      insert(:post, slug: "post-3")

      posts = Posts.list_posts(limit: 2)

      assert length(posts) == 2
    end

    test "orders posts by published_at desc" do
      post1 = insert(:post, slug: "first", published_at: ~U[2024-01-01 00:00:00Z])
      post2 = insert(:post, slug: "second", published_at: ~U[2024-01-02 00:00:00Z])
      post3 = insert(:post, slug: "third", published_at: ~U[2024-01-03 00:00:00Z])

      posts = Posts.list_posts(order_by: [desc: :published_at])

      assert [p3, p2, p1] = posts
      assert p3.id == post3.id
      assert p2.id == post2.id
      assert p1.id == post1.id
    end
  end

  describe "get_post/1" do
    test "gets post by ID" do
      post = insert(:post, slug: "test-post")

      assert fetched = Posts.get_post(post.id)
      assert fetched.id == post.id
      assert fetched.slug == "test-post"
    end

    test "gets post by slug" do
      post = insert(:post, slug: "test-post")

      assert fetched = Posts.get_post(slug: "test-post")
      assert fetched.id == post.id
    end

    test "returns nil when post not found by ID" do
      assert Posts.get_post(999) == nil
    end

    test "returns nil when post not found by slug" do
      assert Posts.get_post(slug: "nonexistent") == nil
    end

    test "filters by is_draft" do
      draft_post = insert(:post, slug: "draft", is_draft: true)
      insert(:post, slug: "published", is_draft: false)

      assert fetched = Posts.get_post(slug: "draft", is_draft: true)
      assert fetched.id == draft_post.id

      assert Posts.get_post(slug: "draft", is_draft: false) == nil
    end
  end

  describe "create_post/1" do
    test "creates a post with valid attributes" do
      attrs = %{
        title: "Test Post",
        raw_body: "# Hello World",
        slug: "test-post"
      }

      assert {:ok, post} = Posts.create_post(attrs)
      assert post.title == "Test Post"
      assert post.slug == "test-post"
      assert post.body =~ "Hello World"
    end

    test "returns error changeset with invalid attributes" do
      attrs = %{title: nil}

      assert {:error, changeset} = Posts.create_post(attrs)
      refute changeset.valid?
    end

    test "returns error changeset with invalid slug format" do
      attrs = %{
        title: "Test Post",
        raw_body: "# Hello",
        slug: "INVALID SLUG"
      }

      assert {:error, changeset} = Posts.create_post(attrs)
      refute changeset.valid?
      assert %{slug: [_error]} = errors_on(changeset)
    end

    test "returns error changeset with duplicate slug" do
      insert(:post, slug: "duplicate")

      attrs = %{
        title: "Test Post",
        raw_body: "# Hello",
        slug: "duplicate"
      }

      assert {:error, changeset} = Posts.create_post(attrs)
      refute changeset.valid?
    end
  end

  describe "update_post/2" do
    test "updates a post with valid attributes" do
      post = insert(:post, title: "Original", slug: "original")

      attrs = %{title: "Updated Title"}

      assert {:ok, updated} = Posts.update_post(post, attrs)
      assert updated.title == "Updated Title"
      assert updated.slug == "original"
    end

    test "updates markdown content" do
      post = insert(:post, raw_body: "# Original", slug: "test")

      attrs = %{raw_body: "# Updated Content"}

      assert {:ok, updated} = Posts.update_post(post, attrs)
      assert updated.body =~ "Updated Content"
    end

    test "returns error changeset with invalid attributes" do
      post = insert(:post, slug: "test")

      attrs = %{slug: "INVALID SLUG"}

      assert {:error, changeset} = Posts.update_post(post, attrs)
      refute changeset.valid?
    end
  end

  describe "upsert_post/1" do
    test "creates a new post when slug doesn't exist" do
      attrs = %{
        title: "New Post",
        raw_body: "# Content",
        slug: "new-post"
      }

      assert {:ok, post} = Posts.upsert_post(attrs)
      assert post.title == "New Post"
      assert post.slug == "new-post"
    end

    test "updates existing post when slug exists" do
      existing = insert(:post, title: "Original", slug: "existing")

      attrs = %{
        title: "Updated",
        raw_body: "# New Content",
        slug: "existing"
      }

      assert {:ok, updated} = Posts.upsert_post(attrs)
      assert updated.id == existing.id
      assert updated.title == "Updated"
    end
  end

  describe "delete_post/1" do
    test "deletes a post" do
      post = insert(:post, slug: "to-delete")

      assert {:ok, deleted} = Posts.delete_post(post)
      assert deleted.id == post.id
      assert Posts.get_post(post.id) == nil
    end
  end
end
