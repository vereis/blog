defmodule Blog.AssetsTest do
  use Blog.DataCase, async: false

  alias Blog.Assets
  alias Blog.Assets.Asset

  @test_image_path Path.join([
                     File.cwd!(),
                     "test/fixtures/priv/assets/test_image.jpg"
                   ])

  describe "list_assets/1" do
    test "returns empty list when no assets exist" do
      assert Assets.list_assets() == []
    end

    test "returns all assets" do
      {:ok, asset1} = Assets.create_asset(%{path: @test_image_path})
      assert [^asset1] = Assets.list_assets()
    end

    test "filters assets by name" do
      {:ok, asset} = Assets.create_asset(%{path: @test_image_path})
      assert [^asset] = Assets.list_assets(name: asset.name)
      assert [] = Assets.list_assets(name: "nonexistent.webp")
    end
  end

  describe "get_asset/1" do
    test "returns asset by ID" do
      {:ok, asset} = Assets.create_asset(%{path: @test_image_path})
      assert ^asset = Assets.get_asset(asset.id)
    end

    test "returns nil for non-existent ID" do
      assert Assets.get_asset(999_999) == nil
    end

    test "returns asset by filters" do
      {:ok, asset} = Assets.create_asset(%{path: @test_image_path})
      assert ^asset = Assets.get_asset(name: asset.name)
    end

    test "returns nil when filter matches nothing" do
      assert Assets.get_asset(name: "nonexistent.webp") == nil
    end
  end

  describe "create_asset/1" do
    test "creates asset with valid attributes" do
      assert {:ok, %Asset{} = asset} = Assets.create_asset(%{path: @test_image_path})
      assert asset.name == "test_image.webp"
      assert asset.content_type == "image/webp"
      assert is_binary(asset.data)
      assert is_integer(asset.width)
      assert is_integer(asset.height)
    end

    test "returns error changeset with invalid attributes" do
      assert {:error, changeset} = Assets.create_asset(%{})
      assert %{path: ["can't be blank"]} = errors_on(changeset)
    end

    test "enforces unique name constraint" do
      {:ok, _asset} = Assets.create_asset(%{path: @test_image_path})

      assert {:error, changeset} = Assets.create_asset(%{path: @test_image_path})
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "update_asset/2" do
    test "updates asset with valid attributes" do
      {:ok, asset} = Assets.create_asset(%{path: @test_image_path})

      assert {:ok, %Asset{} = updated} = Assets.update_asset(asset, %{path: @test_image_path})
      assert updated.id == asset.id
    end
  end

  describe "delete_asset/1" do
    test "deletes asset" do
      {:ok, asset} = Assets.create_asset(%{path: @test_image_path})
      assert {:ok, %Asset{}} = Assets.delete_asset(asset)
      assert Assets.get_asset(asset.id) == nil
    end
  end

  describe "upsert_asset/1" do
    test "inserts new asset when name doesn't exist" do
      assert {:ok, %Asset{} = asset} = Assets.upsert_asset(%{path: @test_image_path})
      assert asset.name == "test_image.webp"
      assert Repo.aggregate(Asset, :count) == 1
    end

    test "updates existing asset when name exists" do
      {:ok, original} = Assets.upsert_asset(%{path: @test_image_path})

      assert {:ok, updated} = Assets.upsert_asset(%{path: @test_image_path})
      assert updated.id == original.id
      assert updated.name == original.name
    end

    test "inserts when name doesn't exist" do
      assert {:ok, asset1} = Assets.upsert_asset(%{path: @test_image_path})
      assert Repo.aggregate(Asset, :count) == 1

      Assets.delete_asset(asset1)
      assert Repo.aggregate(Asset, :count) == 0

      assert {:ok, asset2} = Assets.upsert_asset(%{path: @test_image_path})
      assert Repo.aggregate(Asset, :count) == 1
      assert asset2.name == asset1.name
      refute asset2.id == asset1.id
    end
  end
end
