defmodule Blog.TagsTest do
  use Blog.DataCase, async: false

  alias Blog.Tags

  describe "list_tags/1" do
    test "returns all tags" do
      tag1 = insert(:tag, label: "elixir")
      tag2 = insert(:tag, label: "phoenix")

      tags = Tags.list_tags()

      assert length(tags) == 2
      assert Enum.any?(tags, &(&1.id == tag1.id))
      assert Enum.any?(tags, &(&1.id == tag2.id))
    end

    test "returns empty list when no tags exist" do
      assert Tags.list_tags() == []
    end

    test "limits results" do
      insert(:tag, label: "elixir")
      insert(:tag, label: "phoenix")
      insert(:tag, label: "ecto")

      tags = Tags.list_tags(limit: 2)

      assert length(tags) == 2
    end

    test "orders tags by label asc" do
      insert(:tag, label: "zulu")
      insert(:tag, label: "alpha")
      insert(:tag, label: "bravo")

      tags = Tags.list_tags(order_by: [asc: :label])

      assert [t1, t2, t3] = tags
      assert t1.label == "alpha"
      assert t2.label == "bravo"
      assert t3.label == "zulu"
    end

    test "filters tags having posts" do
      tag_with_post = insert(:tag, label: "elixir")
      tag_without_post = insert(:tag, label: "unused")
      _post = insert(:post, tags: [tag_with_post])

      tags = Tags.list_tags(having: :posts)

      assert length(tags) == 1
      assert hd(tags).id == tag_with_post.id
      refute Enum.any?(tags, &(&1.id == tag_without_post.id))
    end

    test "filters tags having projects" do
      tag_with_project = insert(:tag, label: "elixir")
      tag_without_project = insert(:tag, label: "unused")
      _project = insert(:project, tags: [tag_with_project])

      tags = Tags.list_tags(having: :projects)

      assert length(tags) == 1
      assert hd(tags).id == tag_with_project.id
      refute Enum.any?(tags, &(&1.id == tag_without_project.id))
    end

    test "returns empty list when filtering by association with no items" do
      insert(:tag, label: "unused")

      assert Tags.list_tags(having: :posts) == []
      assert Tags.list_tags(having: :projects) == []
    end
  end

  describe "get_tag/1" do
    test "gets tag by ID" do
      tag = insert(:tag, label: "elixir")

      assert fetched = Tags.get_tag(tag.id)
      assert fetched.id == tag.id
      assert fetched.label == "elixir"
    end

    test "gets tag by label" do
      tag = insert(:tag, label: "elixir")

      assert fetched = Tags.get_tag(label: "elixir")
      assert fetched.id == tag.id
    end

    test "returns nil when tag not found by ID" do
      assert Tags.get_tag(999) == nil
    end

    test "returns nil when tag not found by label" do
      assert Tags.get_tag(label: "nonexistent") == nil
    end
  end

  describe "create_tag/1" do
    test "creates a tag with valid attributes" do
      attrs = %{label: "elixir"}

      assert {:ok, tag} = Tags.create_tag(attrs)
      assert tag.label == "elixir"
    end

    test "returns error with invalid attributes" do
      assert {:error, changeset} = Tags.create_tag(%{})
      assert %{label: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error with duplicate label" do
      insert(:tag, label: "elixir")

      assert {:error, changeset} =
               Tags.create_tag(%{label: "elixir"})

      assert %{label: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "update_tag/2" do
    test "updates tag with valid attributes" do
      tag = insert(:tag, label: "elixir")

      attrs = %{label: "phoenix"}

      assert {:ok, updated} = Tags.update_tag(tag, attrs)
      assert updated.label == "phoenix"
    end

    test "returns error with invalid attributes" do
      tag = insert(:tag)

      assert {:error, changeset} = Tags.update_tag(tag, %{label: nil})
      assert %{label: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "upsert_tag/1" do
    test "creates tag when it doesn't exist" do
      attrs = %{label: "elixir"}

      assert {:ok, tag} = Tags.upsert_tag(attrs)
      assert tag.label == "elixir"
    end

    test "updates tag when it exists" do
      existing = insert(:tag, label: "elixir")

      attrs = %{label: "elixir"}

      assert {:ok, updated} = Tags.upsert_tag(attrs)
      assert updated.id == existing.id
      assert updated.label == "elixir"
    end
  end

  describe "delete_tag/1" do
    test "deletes tag" do
      tag = insert(:tag)

      assert {:ok, deleted} = Tags.delete_tag(tag)
      assert deleted.id == tag.id
      assert Tags.get_tag(tag.id) == nil
    end
  end
end
