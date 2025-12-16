defmodule BlogWeb.PermalinkController do
  use BlogWeb, :controller

  alias Blog.Posts

  def show(conn, %{"permalink" => permalink}) do
    case Posts.get_post(permalink: permalink, is_draft: false) do
      nil ->
        conn
        |> put_flash(:error, {"Page Not Found", "The page you're looking for doesn't exist."})
        |> redirect(to: ~p"/")

      post ->
        redirect(conn, to: ~p"/posts/#{post.slug}")
    end
  end
end
