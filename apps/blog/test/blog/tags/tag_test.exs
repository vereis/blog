defmodule Blog.Tags.TagTest do
  use Blog.DataCase, async: false

  alias Blog.Tags.Tag

  describe "changeset/2 - validation" do
    test "validates required fields" do
      changeset = Tag.changeset(%Tag{}, %{})

      refute changeset.valid?
      assert %{label: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid tag attributes" do
      changeset =
        Tag.changeset(%Tag{}, %{
          label: "elixir"
        })

      assert changeset.valid?
    end

    test "enforces unique label constraint" do
      attrs = %{label: "elixir"}

      {:ok, _tag} = %Tag{} |> Tag.changeset(attrs) |> Repo.insert()

      assert {:error, changeset} = %Tag{} |> Tag.changeset(attrs) |> Repo.insert()
      assert %{label: ["has already been taken"]} = errors_on(changeset)
    end
  end
end
