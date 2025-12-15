defmodule BlogWeb.HomeLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Bluescreen
  alias BlogWeb.Components.Discord
  alias BlogWeb.Components.Post
  alias BlogWeb.Components.TableOfContents
  alias BlogWeb.Components.Viewers

  @slug "hello-world"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")
      Phoenix.PubSub.subscribe(Blog.PubSub, "discord:presence")

      # Track viewer on both site-wide and page-specific topics
      Viewers.track_viewer(self(), Viewers.site_topic(), socket.id)
      Viewers.track_viewer(self(), Viewers.page_topic(:home), socket.id)

      # Subscribe to viewer count updates
      Viewers.subscribe(Viewers.site_topic())
      Viewers.subscribe(Viewers.page_topic(:home))
    end

    socket =
      socket
      |> assign(:post, Blog.Posts.get_post(slug: @slug))
      |> assign(:presence, Blog.Discord.get_presence())
      |> assign(:site_viewer_count, Viewers.count())
      |> assign(:page_viewer_count, Viewers.count(:home))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:resource_reload, Blog.Posts.Post, changed_id}, socket) do
    cond do
      # If for some reason we don't have a post yet and we get a reload, try
      # loading the intended post again.
      is_nil(socket.assigns.post) ->
        {:noreply, assign(socket, :post, Blog.Posts.get_post(slug: @slug))}

      # Otherwise, if we get updates for the post we are displaying, reload it.
      socket.assigns.post.id == changed_id ->
        {:noreply, assign(socket, :post, Blog.Posts.get_post(slug: @slug))}

      true ->
        {:noreply, socket}
    end
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

      topic == Viewers.page_topic(:home) ->
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
    # Ignore raw presence_diff broadcasts - we handle viewer count updates via custom messages
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <:aside>
        <Discord.presence presence={@presence} />
        <Viewers.counts site_count={@site_viewer_count} page_count={@page_viewer_count} />

        <TableOfContents.toc
          headings={
            if is_struct(@post) and length(@post.headings || []) > 1,
              do: @post.headings,
              else: []
          }
          id={if @post, do: "toc-#{@post.slug}", else: "toc"}
        />
      </:aside>

      <%= if @post do %>
        <Post.full post={@post} />
      <% else %>
        <Bluescreen.bluescreen error={:post_not_found} href="/" />
      <% end %>
    </Layouts.app>
    """
  end
end
