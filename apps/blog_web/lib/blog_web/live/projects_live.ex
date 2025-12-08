defmodule BlogWeb.ProjectsLive do
  @moduledoc false
  use BlogWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Projects")
  end

  defp apply_action(socket, :show, %{"slug" => slug}) do
    socket
    |> assign(:page_title, "Project: #{slug}")
    |> assign(:slug, slug)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <%= case @live_action do %>
        <% :index -> %>
          <h1>Projects</h1>
          <p>All projects will be listed here.</p>
        <% :show -> %>
          <h1>Project: {@slug}</h1>
          <p>Individual project content will be rendered here.</p>
      <% end %>
    </Layouts.app>
    """
  end
end
