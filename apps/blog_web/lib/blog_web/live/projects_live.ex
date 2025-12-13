defmodule BlogWeb.ProjectsLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias Blog.Schema.FTS
  alias BlogWeb.Components.Project
  alias BlogWeb.Components.Search
  alias BlogWeb.Components.Tag

  @base_url "/projects"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "project:reload")
    end

    socket =
      socket
      |> assign(:all_tags, Blog.Tags.list_tags(having: :projects))
      |> assign(:projects, [])

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    selected_tags = Tag.labels_from_params(params)
    search_query = Search.query_from_params(params)

    socket =
      socket
      |> assign(:selected_tags, selected_tags)
      |> assign(:search_query, search_query)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"q" => query}, socket) do
    params = Search.build_query_params(query, socket.assigns.selected_tags)
    {:noreply, push_patch(socket, to: "#{@base_url}?#{params}")}
  end

  @impl Phoenix.LiveView
  def handle_info({:resource_reload, Blog.Projects.Project, _id}, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, %{})}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Projects")
    |> assign(
      :projects,
      Blog.Projects.list_projects(
        search: socket.assigns[:search_query],
        tags: socket.assigns[:selected_tags],
        order_by: [desc: :inserted_at]
      )
    )
  rescue
    e in Exqlite.Error ->
      if FTS.fts_error?(e) do
        socket
        |> assign(:page_title, "Projects")
        |> assign(:projects, [])
        |> put_flash(:error, {"Search Error!", "Invalid search query syntax"})
      else
        reraise e, __STACKTRACE__
      end
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
        search_query={@search_query}
      />
    </Layouts.app>
    """
  end
end
