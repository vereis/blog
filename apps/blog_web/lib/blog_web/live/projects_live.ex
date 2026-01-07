defmodule BlogWeb.ProjectsLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias Blog.Schema.FTS
  alias BlogWeb.Components.Aside.Discord
  alias BlogWeb.Components.Aside.Options
  alias BlogWeb.Components.Aside.Toc
  alias BlogWeb.Components.Aside.Viewers
  alias BlogWeb.Components.Project
  alias BlogWeb.Components.Search
  alias BlogWeb.Components.Tag

  @base_url "/projects"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, Blog.Content.pubsub_topic())
      Phoenix.PubSub.subscribe(Blog.PubSub, "discord:presence")

      # Track viewer on both site-wide and page-specific topics
      Viewers.track_viewer(self(), Viewers.site_topic(), socket.id)
      Viewers.track_viewer(self(), Viewers.page_topic(:projects), socket.id)

      # Subscribe to viewer count updates
      Viewers.subscribe(Viewers.site_topic())
      Viewers.subscribe(Viewers.page_topic(:projects))
    end

    socket =
      socket
      |> assign(:all_tags, Blog.Tags.list_tags(having: :projects))
      |> assign(:projects, [])
      |> assign(:presence, Blog.Discord.get_presence())
      |> assign(:site_viewer_count, Viewers.count())
      |> assign(:page_viewer_count, Viewers.count(:projects))

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
  def handle_info({:content_imported}, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, %{})}
  end

  @impl Phoenix.LiveView
  def handle_info({:presence_updated, presence}, socket) do
    {:noreply, assign(socket, :presence, presence)}
  end

  @impl Phoenix.LiveView
  def handle_info({:viewer_count_updated, topic, count}, socket) do
    cond do
      topic == Viewers.site_topic() ->
        {:noreply, assign(socket, :site_viewer_count, count)}

      topic == Viewers.page_topic(:projects) ->
        {:noreply, assign(socket, :page_viewer_count, count)}

      true ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:viewer_joined, _topic}, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_info({:viewer_left, _topic}, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket}
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
    <Layouts.app flash={@flash} current_path="/projects">
      <:aside>
        <Options.options />
        <Discord.presence presence={@presence} />
        <Viewers.counts site_count={@site_viewer_count} page_count={@page_viewer_count} />

        <Toc.toc headings={[]} id="toc" />
      </:aside>

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
