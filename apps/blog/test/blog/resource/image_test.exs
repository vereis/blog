defmodule Blog.Resource.ImageTest do
  use Blog.DataCase, async: false

  alias Blog.Images.Image
  alias Blog.Repo.SQLite
  alias Blog.Resource.Image, as: ImageResource

  describe "source/0" do
    test "returns development path when in development" do
      path = ImageResource.source()
      assert is_binary(path)
      assert String.ends_with?(path, "images")
    end
  end

  describe "parse/1" do
    test "returns path for given filename" do
      filename = "test-image.jpg"
      result = ImageResource.parse(filename)

      expected_path = Path.join(ImageResource.source(), filename)
      assert result.path == expected_path
    end

    test "handles different image extensions" do
      extensions = ["jpg", "jpeg", "png", "gif", "webp"]

      for ext <- extensions do
        filename = "image.#{ext}"
        result = ImageResource.parse(filename)

        expected_path = Path.join(ImageResource.source(), filename)
        assert result.path == expected_path
      end
    end
  end

  describe "import/1" do
    setup do
      {:ok, temp_dir} = Briefly.create(directory: true)
      images_dir = Path.join(temp_dir, "images")
      File.mkdir_p!(images_dir)

      # Create test image files using the factory's PNG data
      png_data = <<
        # PNG signature
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        # IHDR chunk
        # length
        0x00,
        0x00,
        0x00,
        0x0D,
        # type
        0x49,
        0x48,
        0x44,
        0x52,
        # width = 1
        0x00,
        0x00,
        0x00,
        0x01,
        # height = 1
        0x00,
        0x00,
        0x00,
        0x01,
        # bit depth=8, color=2, compression=0, filter=0, interlace=0
        0x08,
        0x02,
        0x00,
        0x00,
        0x00,
        # CRC
        0x90,
        0x77,
        0x53,
        0xDE,
        # IDAT chunk
        # length
        0x00,
        0x00,
        0x00,
        0x0C,
        # type
        0x49,
        0x44,
        0x41,
        0x54,
        # compressed data
        0x08,
        0x1D,
        0x01,
        0x01,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0x00,
        0x02,
        0x00,
        0x01,
        # CRC
        0x73,
        0x75,
        0x01,
        0x18,
        # IEND chunk
        # length
        0x00,
        0x00,
        0x00,
        0x00,
        # type
        0x49,
        0x45,
        0x4E,
        0x44,
        # CRC
        0xAE,
        0x42,
        0x60,
        0x82
      >>

      image1_path = Path.join(images_dir, "image1.png")
      image2_path = Path.join(images_dir, "image2.png")

      File.write!(image1_path, png_data)
      File.write!(image2_path, png_data)

      stub(ImageResource, :source, fn -> images_dir end)

      %{images_dir: images_dir, image1_path: image1_path, image2_path: image2_path}
    end

    test "imports images successfully", %{image1_path: image1_path, image2_path: image2_path} do
      parsed_images = [
        %{path: image1_path},
        %{path: image2_path}
      ]

      assert {:ok, imported_images} = ImageResource.import(parsed_images)
      assert length(imported_images) == 2

      # Verify images were created
      images = SQLite.all(Image)
      assert length(images) == 2

      image_names = Enum.map(images, & &1.name)
      assert "image1.webp" in image_names
      assert "image2.webp" in image_names

      # Verify images have correct data
      for image <- images do
        assert image.content_type == "image/webp"
        assert is_binary(image.data)
        assert byte_size(image.data) > 0
        assert image.width == 1
        assert image.height == 1
      end
    end

    test "handles empty list" do
      assert {:ok, []} = ImageResource.import([])
      assert SQLite.all(Image) == []
    end

    test "handles duplicate paths by updating existing" do
      {:ok, temp_dir} = Briefly.create(directory: true)
      images_dir = Path.join(temp_dir, "images")
      File.mkdir_p!(images_dir)

      # Use the same PNG data as in setup
      png_data = <<
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x02,
        0x00,
        0x00,
        0x00,
        0x90,
        0x77,
        0x53,
        0xDE,
        0x00,
        0x00,
        0x00,
        0x0C,
        0x49,
        0x44,
        0x41,
        0x54,
        0x08,
        0x1D,
        0x01,
        0x01,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0x00,
        0x02,
        0x00,
        0x01,
        0x73,
        0x75,
        0x01,
        0x18,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82
      >>

      duplicate_path = Path.join(images_dir, "duplicate.png")
      File.write!(duplicate_path, png_data)

      stub(ImageResource, :source, fn -> images_dir end)

      parsed_images = [
        %{path: duplicate_path},
        # Same path twice
        %{path: duplicate_path}
      ]

      assert {:ok, imported_images} = ImageResource.import(parsed_images)
      assert length(imported_images) == 2

      # Should only create one image (upsert behavior)
      images = SQLite.all(Image)
      assert length(images) == 1
      assert hd(images).name == "duplicate.webp"
    end
  end
end
