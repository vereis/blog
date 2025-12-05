defmodule Blog.Utils.GuardsTest do
  use Blog.DataCase, async: true

  import Blog.Utils.Guards
  import Ecto.Changeset

  alias Blog.Posts.Post

  describe "valid?/1" do
    test "returns true for valid changeset" do
      changeset =
        %Post{}
        |> cast(%{title: "Test", slug: "test", raw_body: "body"}, [:title, :slug, :raw_body])
        |> validate_required([:title, :slug, :raw_body])

      assert valid?(changeset)
    end

    test "returns false for invalid changeset" do
      changeset =
        %Post{}
        |> cast(%{}, [:title, :slug, :raw_body])
        |> validate_required([:title, :slug, :raw_body])

      refute valid?(changeset)
    end

    test "returns false for non-changeset structs" do
      refute valid?(%Post{})
    end

    test "returns false for non-struct values" do
      refute valid?(%{valid?: true})
    end
  end

  describe "changes?/2" do
    test "returns true when field has changes" do
      changeset = cast(%Post{}, %{title: "Test Title"}, [:title])

      assert changes?(changeset, :title)
    end

    test "returns false when field has no changes" do
      changeset = cast(%Post{}, %{title: "Test Title"}, [:title])

      refute changes?(changeset, :slug)
    end

    test "returns false for invalid field" do
      changeset = cast(%Post{}, %{title: "Test Title"}, [:title])

      refute changes?(changeset, :nonexistent_field)
    end

    test "returns false for non-changeset structs" do
      refute changes?(%Post{}, :title)
    end

    test "returns false for non-struct values" do
      refute changes?(%{changes: %{title: "Test"}}, :title)
    end
  end
end
