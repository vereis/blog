defmodule BlogWeb.RedirectController do
  use BlogWeb, :controller

  plug :put_layout, false
  plug :put_root_layout, false

  def minna_chat(conn, _params) do
    redirect(conn, external: "https://discord.gg/WGGhk5wjYT")
  end
end
