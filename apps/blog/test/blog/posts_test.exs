defmodule Blog.PostsTest do
  use Blog.DataCase, async: true

  import ExUnit.CaptureLog

  alias Blog.Posts

  describe "get_post/1" do
    test "gets post by id" do
      post = insert(:post, title: "Test Post", slug: "test-post")

      result = Posts.get_post(post.id)
      assert result.id == post.id
      assert result.title == "Test Post"
    end

    test "gets post by filters" do
      post = insert(:post, title: "Test Post", slug: "test-post")

      result = Posts.get_post(slug: "test-post")
      assert result.id == post.id
      assert result.title == "Test Post"
    end

    test "returns nil when post not found" do
      assert Posts.get_post(999) == nil
      assert Posts.get_post(slug: "nonexistent") == nil
    end

    test "preloads tags" do
      tag = insert(:tag, label: "elixir")
      post = insert(:post, title: "Test Post", slug: "test-post", tags: [tag])

      result = Posts.get_post(post.id)
      assert length(result.tags) == 1
      assert hd(result.tags).label == "elixir"
    end
  end

  describe "list_posts/1" do
    test "lists all non-redacted posts" do
      insert(:post, title: "Post 1", slug: "post-1", is_redacted: false)
      insert(:post, title: "Post 2", slug: "post-2", is_redacted: false)
      insert(:redacted_post, title: "Redacted", slug: "redacted")

      posts = Posts.list_posts()
      assert length(posts) == 2

      titles = Enum.map(posts, & &1.title)
      assert "Post 1" in titles
      assert "Post 2" in titles
      refute "Redacted" in titles
    end

    test "accepts additional filters" do
      insert(:draft_post, title: "Draft", slug: "draft")
      insert(:post, title: "Published", slug: "published", is_draft: false)

      published_posts = Posts.list_posts(is_draft: false)
      assert length(published_posts) == 1
      assert hd(published_posts).title == "Published"
    end

    test "preloads tags" do
      tag = insert(:tag, label: "elixir")
      insert(:post, title: "Test Post", slug: "test-post", tags: [tag])

      [post] = Posts.list_posts()
      assert length(post.tags) == 1
      assert hd(post.tags).label == "elixir"
    end

    test "returns empty list when no posts exist" do
      assert Posts.list_posts() == []
    end
  end

  describe "upsert_post/1" do
    test "creates new post when slug doesn't exist" do
      attrs = %{
        title: "New Post",
        slug: "new-post",
        raw_body: "# Hello\n\nThis is content."
      }

      assert {:ok, post} = Posts.upsert_post(attrs)
      assert post.title == "New Post"
      assert post.slug == "new-post"
      # HTML was generated
      assert String.contains?(post.body, "<h1")
      # Description was generated
      assert String.contains?(post.description, "Hello")
    end

    test "updates existing post when slug exists" do
      existing = insert(:post, title: "Original", slug: "test-post")

      attrs = %{
        title: "Updated Title",
        slug: "test-post",
        raw_body: "Updated content"
      }

      assert {:ok, updated} = Posts.upsert_post(attrs)
      assert updated.id == existing.id
      assert updated.title == "Updated Title"
      assert updated.raw_body == "Updated content"
    end

    test "handles validation errors" do
      # Missing required title
      attrs = %{slug: "test-post"}

      assert {:error, changeset} = Posts.upsert_post(attrs)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "associates tags by tag_ids" do
      tag1 = insert(:tag, label: "elixir")
      tag2 = insert(:tag, label: "web")

      attrs = %{
        title: "Tagged Post",
        slug: "tagged-post",
        raw_body: "Content",
        tag_ids: [tag1.id, tag2.id]
      }

      assert {:ok, post} = Posts.upsert_post(attrs)
      post_with_tags = Posts.get_post(post.id)

      tag_labels = Enum.map(post_with_tags.tags, & &1.label)
      assert "elixir" in tag_labels
      assert "web" in tag_labels
    end
  end

  describe "get_tag/1" do
    test "gets tag by id" do
      tag = insert(:tag, label: "elixir")

      result = Posts.get_tag(tag.id)
      assert result.id == tag.id
      assert result.label == "elixir"
    end

    test "gets tag by filters" do
      tag = insert(:tag, label: "elixir")

      result = Posts.get_tag(label: "elixir")
      assert result.id == tag.id
      assert result.label == "elixir"
    end

    test "returns nil when tag not found" do
      assert Posts.get_tag(999) == nil
      assert Posts.get_tag(label: "nonexistent") == nil
    end
  end

  describe "list_tags/1" do
    test "lists all tags" do
      insert(:tag, label: "elixir")
      insert(:tag, label: "web")

      tags = Posts.list_tags()
      assert length(tags) == 2

      labels = Enum.map(tags, & &1.label)
      assert "elixir" in labels
      assert "web" in labels
    end

    test "accepts filters" do
      insert(:tag, label: "elixir")
      insert(:tag, label: "web")

      filtered = Posts.list_tags(label: "elixir")
      assert length(filtered) == 1
      assert hd(filtered).label == "elixir"
    end

    test "returns empty list when no tags exist" do
      assert Posts.list_tags() == []
    end
  end

  describe "FTS error handling" do
    test "list_posts/1 gracefully handles FTS syntax errors and logs warning" do
      log =
        capture_log(fn ->
          # These would normally crash with Exqlite.Error, but should return empty list
          assert Posts.list_posts(search: "elixir ||| invalid") == []
        end)

      assert log =~ "FTS query error in list_posts/1"
    end

    test "get_post/1 gracefully handles FTS syntax errors and logs warning" do
      log =
        capture_log(fn ->
          # Should return nil instead of crashing
          assert Posts.get_post(search: "\"unterminated quote") == nil
        end)

      assert log =~ "FTS query error in get_post/1"
    end
  end

  describe "upsert_tag/1" do
    test "creates new tag when label doesn't exist" do
      attrs = %{label: "new-tag"}

      assert {:ok, tag} = Posts.upsert_tag(attrs)
      assert tag.label == "new-tag"
    end

    test "updates existing tag when label exists" do
      existing = insert(:tag, label: "existing")

      # Tags don't have other fields to update, but this tests the upsert logic
      attrs = %{label: "existing"}

      assert {:ok, updated} = Posts.upsert_tag(attrs)
      assert updated.id == existing.id
      assert updated.label == "existing"
    end

    test "handles validation errors" do
      # Missing required label
      attrs = %{}

      assert {:error, changeset} = Posts.upsert_tag(attrs)
      assert %{label: ["can't be blank"]} = errors_on(changeset)
    end

    test "handles duplicate labels by updating existing" do
      existing = insert(:tag, label: "duplicate")

      # Try to create another tag with same label - should update existing
      assert {:ok, updated_tag} = Posts.upsert_tag(%{label: "duplicate"})
      assert updated_tag.id == existing.id
      assert updated_tag.label == "duplicate"
    end
  end
end
