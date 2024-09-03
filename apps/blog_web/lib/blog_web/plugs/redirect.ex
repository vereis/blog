defmodule BlogWeb.Plugs.Redirect do
  @moduledoc "Handles redirecting based on hostname"

  import Plug.Conn

  alias Phoenix.Controller

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    if conn.host =~ "cbailey.co.uk" do
      conn
      |> Controller.redirect(external: "https://vereis.com/")
      |> halt()
    else
      conn
    end
  end
end
