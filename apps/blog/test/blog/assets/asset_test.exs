defmodule Blog.Assets.AssetTest do
  use Blog.DataCase, async: false

  alias Blog.Assets.Asset
  alias Ecto.Changeset

  @test_image_path Path.join([
                     File.cwd!(),
                     "test/fixtures/priv/assets/test_image.jpg"
                   ])

  describe "changeset/2 - validation" do
    test "validates required path field" do
      changeset = Asset.changeset(%Asset{}, %{})

      refute changeset.valid?
      assert %{path: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "changeset/2 - image optimization" do
    test "optimizes image to WebP format" do
      changeset = Asset.changeset(%Asset{}, %{path: @test_image_path})

      assert changeset.valid?
      assert {:ok, data} = Changeset.fetch_change(changeset, :data)
      assert is_binary(data)
      assert byte_size(data) > 0
    end

    test "sets content type to image/webp" do
      changeset = Asset.changeset(%Asset{}, %{path: @test_image_path})

      assert changeset.valid?
      assert {:ok, "image/webp"} = Changeset.fetch_change(changeset, :content_type)
    end

    test "extracts image dimensions" do
      changeset = Asset.changeset(%Asset{}, %{path: @test_image_path})

      assert changeset.valid?
      assert {:ok, width} = Changeset.fetch_change(changeset, :width)
      assert {:ok, height} = Changeset.fetch_change(changeset, :height)
      assert is_integer(width)
      assert is_integer(height)
      assert width > 0
      assert height > 0
    end

    test "generates WebP filename from original" do
      changeset = Asset.changeset(%Asset{}, %{path: @test_image_path})

      assert changeset.valid?
      assert {:ok, "test_image.webp"} = Changeset.fetch_change(changeset, :name)
    end
  end

  describe "import/0" do
    test "imports assets from source directory" do
      assert {:ok, imported} = Asset.import()

      refute Enum.empty?(imported)
      assert Repo.aggregate(Asset, :count) >= 1

      asset = List.first(imported)
      assert asset.name =~ ~r/\.webp$/
      assert asset.content_type == "image/webp"
      assert is_binary(asset.data)
      assert is_integer(asset.width)
      assert is_integer(asset.height)
    end
  end
end
