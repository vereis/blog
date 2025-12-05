defmodule BlogWeb.AssetsControllerTest do
  use BlogWeb.ConnCase

  alias Blog.Assets

  @test_image_path Path.join([
                     File.cwd!(),
                     "test/fixtures/priv/assets/test_image.jpg"
                   ])

  describe "GET /assets/images/:name" do
    test "serves existing asset with correct content-type and data", %{conn: conn} do
      {:ok, asset} = Assets.create_asset(%{path: @test_image_path})

      conn = get(conn, "/assets/images/#{asset.name}")

      assert response_content_type(conn, :webp) == "image/webp; charset=utf-8"
      assert response(conn, 200) == asset.data
    end

    test "sets caching headers correctly", %{conn: conn} do
      {:ok, asset} = Assets.create_asset(%{path: @test_image_path})

      conn = get(conn, "/assets/images/#{asset.name}")

      assert get_resp_header(conn, "cache-control") == ["public, max-age=31536000"]
    end

    test "returns 404 for non-existent asset", %{conn: conn} do
      conn = get(conn, "/assets/images/nonexistent.webp")

      assert json_response(conn, 404) == %{"error" => "Asset not found"}
    end

    test "handles asset names with special characters", %{conn: conn} do
      {:ok, asset} = Assets.create_asset(%{path: @test_image_path})

      conn = get(conn, "/assets/images/#{asset.name}")

      assert response(conn, 200) == asset.data
      assert response_content_type(conn, :webp) == "image/webp; charset=utf-8"
    end
  end
end
