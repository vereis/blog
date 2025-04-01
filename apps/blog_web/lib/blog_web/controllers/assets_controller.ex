defmodule BlogWeb.AssetsController do
  use BlogWeb, :controller

  alias Blog.Posts
  alias Blog.Posts.Image

  def show(conn, %{"name" => name}) do
    case Posts.get_image(name: name) do
      %Image{} = image ->
        conn
        |> put_resp_content_type(image.content_type)
        |> send_resp(200, image.data)

      nil ->
        send_resp(conn, 404, "Not found")
    end
  end
end
