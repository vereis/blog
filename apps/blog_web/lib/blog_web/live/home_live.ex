defmodule BlogWeb.HomeLive do
  @moduledoc false
  use BlogWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Home</h1>
      <p>Welcome to the blog!</p>
    </Layouts.app>
    """
  end
end
