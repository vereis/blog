defmodule Blog.Images.ImageTest do
  use Blog.DataCase, async: false

  import Blog.Factory

  alias Blog.Images.Image
  alias Blog.Repo.SQLite

  describe "changeset/2" do
    test "valid changeset with required fields" do
      image = build(:image)
      attrs = %{path: image.path}

      changeset = Image.changeset(%Image{}, attrs)
      assert changeset.valid?

      # Check that optimization fields are set
      assert changeset |> Ecto.Changeset.get_change(:name) |> String.ends_with?(".webp")
      assert Ecto.Changeset.get_change(changeset, :content_type) == "image/webp"
      assert is_binary(Ecto.Changeset.get_change(changeset, :data))
      assert is_integer(Ecto.Changeset.get_change(changeset, :width))
      assert is_integer(Ecto.Changeset.get_change(changeset, :height))
    end

    test "invalid changeset without path" do
      attrs = %{}

      # This will fail because optimize! tries to read a nil path
      assert_raise FunctionClauseError, fn ->
        Image.changeset(%Image{}, attrs)
      end
    end

    test "enforces unique name constraint" do
      insert(:image, name: "duplicate.webp")

      image = build(:image)
      # Force the same name to trigger constraint
      attrs = %{path: image.path}
      changeset = Image.changeset(%Image{}, attrs)

      # Manually set the name to duplicate to test constraint
      changeset = Ecto.Changeset.put_change(changeset, :name, "duplicate.webp")

      assert {:error, changeset} = SQLite.insert(changeset)
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end

    test "optimizes image and sets metadata" do
      image = build(:image)
      attrs = %{path: image.path}

      changeset = Image.changeset(%Image{}, attrs)

      # Verify optimization happened
      optimized_name = Ecto.Changeset.get_change(changeset, :name)
      assert String.ends_with?(optimized_name, ".webp")

      # Verify metadata was extracted
      assert Ecto.Changeset.get_change(changeset, :width) == 1
      assert Ecto.Changeset.get_change(changeset, :height) == 1
      assert Ecto.Changeset.get_change(changeset, :content_type) == "image/webp"

      # Verify data was converted to WebP
      optimized_data = Ecto.Changeset.get_change(changeset, :data)
      assert is_binary(optimized_data)
      assert byte_size(optimized_data) > 0
    end

    test "handles invalid image files gracefully" do
      {:ok, temp_file} = Briefly.create()
      File.write!(temp_file, "not an image")

      attrs = %{path: temp_file}

      assert_raise MatchError, fn ->
        Image.changeset(%Image{}, attrs)
      end
    end
  end

  describe "query/2" do
    test "applies filters correctly" do
      image1 = insert(:image, width: 800, height: 600)
      image2 = insert(:image, width: 1920, height: 1080)

      # Test width filter
      query = Image.query(Image, width: 800)
      results = SQLite.all(query)
      assert length(results) == 1
      assert hd(results).id == image1.id

      # Test height filter
      query = Image.query(Image, height: 1080)
      results = SQLite.all(query)
      assert length(results) == 1
      assert hd(results).id == image2.id

      # Test name filter
      query = Image.query(Image, name: image1.name)
      results = SQLite.all(query)
      assert length(results) == 1
      assert hd(results).id == image1.id
    end
  end
end
