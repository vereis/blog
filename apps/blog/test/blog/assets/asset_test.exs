defmodule Blog.Assets.AssetTest do
  use Blog.DataCase, async: false

  alias Blog.Assets.Asset
  alias Ecto.Changeset

  @test_image_path Path.join([
                     File.cwd!(),
                     "test/fixtures/priv/assets/test_image.jpg"
                   ])

  @test_text_path Path.join([
                    File.cwd!(),
                    "test/fixtures/priv/assets/test_document.txt"
                  ])

  @test_pdf_path Path.join([
                   File.cwd!(),
                   "test/fixtures/priv/assets/test_document.pdf"
                 ])

  @invalid_image_path Path.join([
                        File.cwd!(),
                        "test/fixtures/priv/assets/invalid_image.jpg"
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

    test "generates LQIP hash for image" do
      changeset = Asset.changeset(%Asset{}, %{path: @test_image_path})

      assert changeset.valid?
      assert {:ok, lqip_hash} = Changeset.fetch_change(changeset, :lqip_hash)
      assert is_integer(lqip_hash)
      # Verify the hash is within valid 20-bit signed range
      assert lqip_hash >= -524_288 and lqip_hash <= 524_287
      # Verify the specific hash for test_image.jpg (regression test)
      assert lqip_hash == -169_437
    end

    test "handles invalid image files gracefully" do
      changeset = Asset.changeset(%Asset{}, %{path: @invalid_image_path})

      refute changeset.valid?
      assert {"Failed to load image: " <> _, _} = changeset.errors[:path]
    end

    test "handles missing image files gracefully" do
      changeset = Asset.changeset(%Asset{}, %{path: "/nonexistent/path/image.jpg"})

      refute changeset.valid?
      assert {"Failed to load image: " <> _, _} = changeset.errors[:path]
    end
  end

  describe "changeset/2 - unimplemented types" do
    test "returns type error for text files" do
      changeset = Asset.changeset(%Asset{}, %{path: @test_text_path})

      refute changeset.valid?
      assert {"Asset type handling not implemented", _} = changeset.errors[:type]
    end

    test "returns type error for PDF files" do
      changeset = Asset.changeset(%Asset{}, %{path: @test_pdf_path})

      refute changeset.valid?
      assert {"Asset type handling not implemented", _} = changeset.errors[:type]
    end

    test "does not set type field for unimplemented types" do
      changeset = Asset.changeset(%Asset{}, %{path: @test_text_path})

      # Type field is not set because the changeset is invalid
      assert :error = Changeset.fetch_change(changeset, :type)
    end
  end

  describe "import/0" do
    @tag :capture_log
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
