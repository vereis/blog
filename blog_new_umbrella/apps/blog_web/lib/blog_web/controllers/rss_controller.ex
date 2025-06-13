defmodule BlogWeb.RssController do
  use BlogWeb, :controller

  alias Blog.Posts

  plug :put_layout, false
  plug :put_root_layout, false

  def index(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> put_view(BlogWeb.RssView)
    |> render("index.xml", posts: Posts.list_posts())
  end
end
