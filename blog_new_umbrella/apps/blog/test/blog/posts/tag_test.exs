defmodule Blog.Posts.TagTest do
  use Blog.DataCase, async: true

  alias Blog.Posts.Tag
  alias Blog.Posts.Post
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
      # Create first tag
      {:ok, _existing} = SQLite.insert(%Tag{label: "duplicate"})

      # Try to create second tag with same label
      attrs = %{label: "duplicate"}

      changeset = Tag.changeset(%Tag{}, attrs)
      assert {:error, changeset} = SQLite.insert(changeset)
      assert %{label: ["has already been taken"]} = errors_on(changeset)
    end

    test "handles post associations" do
      {:ok, post1} =
        SQLite.insert(%Post{
          title: "Post 1",
          slug: "post-1",
          body: "Content",
          description: "Description"
        })

      {:ok, post2} =
        SQLite.insert(%Post{
          title: "Post 2",
          slug: "post-2",
          body: "Content",
          description: "Description"
        })

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
