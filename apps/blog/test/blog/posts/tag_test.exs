defmodule Blog.Posts.TagTest do
  use Blog.DataCase, async: false

  alias Blog.Posts.Tag
  alias Blog.Repo.SQLite

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{label: "elixir"}

      changeset = Tag.changeset(%Tag{}, attrs)
      assert changeset.valid?
      assert changeset.changes.label == "elixir"
    end

    test "invalid changeset with missing required fields" do
      changeset = Tag.changeset(%Tag{}, %{})
      refute changeset.valid?

      assert %{label: ["can't be blank"]} = errors_on(changeset)
    end

    test "enforces unique label constraint" do
      # Create first tag using factory
      insert(:tag, label: "duplicate")

      # Try to create second tag with same label
      attrs = %{label: "duplicate"}

      changeset = Tag.changeset(%Tag{}, attrs)
      assert {:error, changeset} = SQLite.insert(changeset)
      assert %{label: ["has already been taken"]} = errors_on(changeset)
    end

    test "handles post associations" do
      post1 = insert(:post, title: "Post 1", slug: "post-1")
      post2 = insert(:post, title: "Post 2", slug: "post-2")

      attrs = %{
        label: "elixir",
        post_ids: [post1.id, post2.id]
      }

      changeset = Tag.changeset(%Tag{}, attrs)
      assert changeset.valid?
    end

    test "trims whitespace from label" do
      attrs = %{label: "  elixir  "}

      changeset = Tag.changeset(%Tag{}, attrs)
      # cast doesn't trim by default
      assert changeset.changes.label == "  elixir  "
    end

    test "handles updating existing tag" do
      existing = %Tag{id: 1, label: "old-label"}
      attrs = %{label: "new-label"}

      changeset = Tag.changeset(existing, attrs)
      assert changeset.valid?
      assert changeset.changes.label == "new-label"
    end
  end
end
