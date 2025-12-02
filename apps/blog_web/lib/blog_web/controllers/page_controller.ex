defmodule BlogWeb.PageController do
  use BlogWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
