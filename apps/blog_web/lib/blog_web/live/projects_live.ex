defmodule BlogWeb.ProjectsLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Project
  alias BlogWeb.Components.Tag

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "project:reload")
    end

    all_tags = Blog.Tags.list_tags()

    socket =
      socket
      |> assign(:all_tags, all_tags)
      |> assign(:projects, [])

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    selected_tags = Tag.labels_from_params(params)
    socket = assign(socket, :selected_tags, selected_tags)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_info({:resource_reload, Blog.Projects.Project, _id}, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, %{})}
  end

  defp apply_action(socket, :index, _params) do
    projects = Blog.Projects.list_projects(tags: socket.assigns[:selected_tags], order_by: [desc: :inserted_at])

    socket
    |> assign(:page_title, "Projects")
    |> assign(:projects, projects)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <Project.list
        projects={@projects}
        id="projects"
        all_tags={@all_tags}
        selected_tags={@selected_tags}
      />
    </Layouts.app>
    """
  end
end
