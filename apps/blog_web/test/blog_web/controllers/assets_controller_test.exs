defmodule BlogWeb.AssetsControllerTest do
  use BlogWeb.ConnCase

  import Blog.Factory

  describe "GET /assets/images/:name" do
    test "returns image when it exists", %{conn: conn} do
      image =
        insert(:image,
          name: "test-image.png",
          content_type: "image/png",
          # PNG header
          data: <<137, 80, 78, 71, 13, 10, 26, 10>>
        )

      conn = get(conn, ~p"/assets/images/#{image.name}")

      assert response(conn, 200)
      assert response_content_type(conn, :png) =~ "image/png"
      assert response(conn, 200) == image.data
    end

    test "returns 404 when image does not exist", %{conn: conn} do
      conn = get(conn, ~p"/assets/images/nonexistent.png")

      assert response(conn, 404)
      assert response(conn, 404) == "Not found"
    end

    test "serves different content types correctly", %{conn: conn} do
      jpg_image =
        insert(:image,
          name: "test.jpg",
          content_type: "image/jpeg",
          # JPEG header
          data: <<255, 216, 255, 224>>
        )

      svg_image =
        insert(:image,
          name: "test.svg",
          content_type: "image/svg+xml",
          data: "<svg></svg>"
        )

      # Test JPEG
      conn = get(conn, ~p"/assets/images/#{jpg_image.name}")
      assert response_content_type(conn, :jpeg) =~ "image/jpeg"

      # Reset connection and test SVG
      conn = build_conn()
      conn = get(conn, ~p"/assets/images/#{svg_image.name}")
      assert response_content_type(conn, :svg) =~ "image/svg+xml"
    end

    test "handles binary data correctly", %{conn: conn} do
      binary_data = :crypto.strong_rand_bytes(1024)

      image =
        insert(:image,
          name: "binary-test.png",
          content_type: "image/png",
          data: binary_data
        )

      conn = get(conn, ~p"/assets/images/#{image.name}")

      assert response(conn, 200) == binary_data
      assert byte_size(response(conn, 200)) == 1024
    end
  end
end
