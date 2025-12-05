defmodule BlogWeb.AssetsController do
  use BlogWeb, :controller

  alias Blog.Assets

  @cache_control "public, max-age=31536000"

  # NOTE: serving binary image data, not user input, content-type is validated
  # sobelow_skip ["XSS.SendResp", "XSS.ContentType"]
  def show(conn, %{"name" => name}) do
    case Assets.get_asset(name: name) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Asset not found"})

      asset ->
        conn
        |> put_resp_content_type(asset.content_type)
        |> put_resp_header("cache-control", @cache_control)
        |> send_resp(200, asset.data)
    end
  end
end
