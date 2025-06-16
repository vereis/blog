defmodule Blog.ImagesTest do
  use Blog.DataCase, async: true

  import Blog.Factory

  alias Blog.Images

  describe "get_image/1" do
    test "gets image by id" do
      image = insert(:image, name: "test-image.webp", path: "/tmp/test.jpg")

      result = Images.get_image(image.id)
      assert result.id == image.id
      assert result.name == "test-image.webp"
    end

    test "gets image by filters" do
      image = insert(:image, name: "test-image.webp", path: "/tmp/test.jpg")

      result = Images.get_image(name: "test-image.webp")
      assert result.id == image.id
      assert result.name == "test-image.webp"
    end

    test "returns nil when image not found" do
      assert Images.get_image(999) == nil
      assert Images.get_image(name: "nonexistent.webp") == nil
    end
  end

  describe "list_images/1" do
    test "lists all images" do
      insert(:image, name: "image1.webp", path: "/tmp/image1.jpg")
      insert(:image, name: "image2.webp", path: "/tmp/image2.jpg")

      images = Images.list_images()
      assert length(images) == 2

      names = Enum.map(images, & &1.name)
      assert "image1.webp" in names
      assert "image2.webp" in names
    end

    test "accepts filters" do
      insert(:image, name: "large.webp", path: "/tmp/large.jpg", width: 1920)
      insert(:image, name: "small.webp", path: "/tmp/small.jpg", width: 800)

      large_images = Images.list_images(width: 1920)
      assert length(large_images) == 1
      assert hd(large_images).name == "large.webp"
    end

    test "returns empty list when no images exist" do
      assert Images.list_images() == []
    end
  end

  describe "upsert_image/1" do
    test "creates new image when path doesn't exist" do
      # Use factory which creates a proper image
      image = build(:image)

      attrs = %{
        path: image.path
      }

      assert {:ok, created_image} = Images.upsert_image(attrs)
      assert String.ends_with?(created_image.name, ".webp")
      assert created_image.content_type == "image/webp"
      assert is_binary(created_image.data)
    end

    test "updates existing image when path exists" do
      # Create a proper temp image file
      {:ok, temp_file} = Briefly.create(extname: ".png")

      # Create a minimal valid 1x1 PNG file
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

      File.write!(temp_file, png_data)

      {:ok, existing} = Images.upsert_image(%{path: temp_file})

      # Update with same path
      assert {:ok, updated} = Images.upsert_image(%{path: temp_file})
      assert updated.id == existing.id
      assert updated.path == temp_file
    end

    test "handles validation errors" do
      # Missing required data/name (will fail in optimize!)
      attrs = %{path: "/nonexistent/file.jpg"}

      assert_raise MatchError, fn ->
        Images.upsert_image(attrs)
      end
    end
  end
end
