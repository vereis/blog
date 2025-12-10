defmodule BlogWeb.ProjectsLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Project

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "project:reload")
    end

    socket =
      socket
      |> assign(:loading, true)
      |> assign(:debug_params, Map.take(params, ["_debug"]))
      |> stream_configure(:projects, dom_id: fn {project, _index} -> "project-#{project.id}" end)
      |> stream(:projects, [])

    send(self(), :load_projects)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    socket = assign(socket, :debug_params, Map.take(params, ["_debug"]))
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_info(:load_projects, socket) do
    if socket.assigns.debug_params["_debug"] == "slow" do
      Process.sleep(5000)
    end

    socket =
      if socket.assigns.live_action == :index and socket.assigns.debug_params["_debug"] != "empty" do
        projects = Blog.Projects.list_projects(order_by: [desc: :inserted_at])
        stream(socket, :projects, Enum.with_index(projects, 1), reset: true)
      else
        socket
      end

    {:noreply, assign(socket, :loading, false)}
  end

  def handle_info({:resource_reload, Blog.Projects.Project, _id}, socket) do
    send(self(), :load_projects)
    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Projects")
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <Project.list projects={@streams.projects} loading={@loading} id="projects" />
    </Layouts.app>
    """
  end
end
