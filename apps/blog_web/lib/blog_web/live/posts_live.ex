defmodule BlogWeb.PostsLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias Blog.Schema.FTS
  alias BlogWeb.Components.Aside.Discord
  alias BlogWeb.Components.Aside.Options
  alias BlogWeb.Components.Aside.Toc
  alias BlogWeb.Components.Aside.Viewers
  alias BlogWeb.Components.Bluescreen
  alias BlogWeb.Components.Post
  alias BlogWeb.Components.Search
  alias BlogWeb.Components.Tag

  @base_url "/posts"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")
      Phoenix.PubSub.subscribe(Blog.PubSub, "discord:presence")

      # Track on site-wide topic
      Viewers.track_viewer(self(), Viewers.site_topic(), socket.id)
      Viewers.subscribe(Viewers.site_topic())
    end

    socket =
      socket
      |> assign(:all_tags, Blog.Tags.list_tags(having: :posts))
      |> assign(:posts, [])
      |> assign(:presence, Blog.Discord.get_presence())
      |> assign(:site_viewer_count, Viewers.count())
      |> assign(:page_viewer_count, 0)
      |> assign(:current_page_topic, nil)
      |> assign(:prev_action, nil)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    selected_tags = Tag.labels_from_params(params)
    search_query = Search.query_from_params(params)
    prev_action = socket.assigns[:prev_action]
    current_action = socket.assigns.live_action

    socket =
      socket
      |> assign(:selected_tags, selected_tags)
      |> assign(:search_query, search_query)
      |> maybe_switch_page_topic(current_action, params)
      |> maybe_scroll_to_top(prev_action, current_action)
      |> assign(:prev_action, current_action)

    {:noreply, apply_action(socket, current_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"q" => query}, socket) do
    params = Search.build_query_params(query, socket.assigns.selected_tags)
    {:noreply, push_patch(socket, to: "#{@base_url}?#{params}")}
  end

  @impl Phoenix.LiveView
  def handle_info({:content_reload, Blog.Posts.Post, _id}, socket) do
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

      topic == socket.assigns.current_page_topic ->
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

  defp maybe_switch_page_topic(socket, live_action, params) do
    new_topic = get_page_topic(live_action, params)
    new_count_arg = get_count_arg(live_action, params)
    old_topic = socket.assigns[:current_page_topic]

    cond do
      # First time tracking (mount)
      is_nil(old_topic) and connected?(socket) ->
        Viewers.track_viewer(self(), new_topic, socket.id)
        Viewers.subscribe(new_topic)

        socket
        |> assign(:current_page_topic, new_topic)
        |> assign(:page_viewer_count, Viewers.count(new_count_arg))

      # Topic changed (navigation)
      old_topic != new_topic and connected?(socket) ->
        Viewers.untrack_viewer(self(), old_topic, socket.id)
        Viewers.track_viewer(self(), new_topic, socket.id)
        Viewers.subscribe(new_topic)

        socket
        |> assign(:current_page_topic, new_topic)
        |> assign(:page_viewer_count, Viewers.count(new_count_arg))

      # No change or not connected
      true ->
        socket
    end
  end

  defp get_page_topic(:index, _params), do: Viewers.page_topic(:posts)
  defp get_page_topic(:show, %{"slug" => slug}), do: Viewers.post_topic(slug)

  defp get_count_arg(:index, _params), do: :posts
  defp get_count_arg(:show, %{"slug" => slug}), do: [posts: slug]

  defp maybe_scroll_to_top(socket, prev_action, current_action) when prev_action != current_action do
    push_event(socket, "scroll-to-top", %{})
  end

  defp maybe_scroll_to_top(socket, _prev_action, _current_action), do: socket

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Posts")
    |> assign(
      :posts,
      Blog.Posts.list_posts(
        search: socket.assigns[:search_query],
        tags: socket.assigns[:selected_tags],
        order_by: [desc: :published_at]
      )
    )
  rescue
    e in Exqlite.Error ->
      if FTS.fts_error?(e) do
        socket
        |> assign(:page_title, "Posts")
        |> assign(:posts, [])
        |> put_flash(:error, {"Search Error!", "Invalid search query syntax"})
      else
        reraise e, __STACKTRACE__
      end
  end

  defp apply_action(socket, :show, %{"slug" => slug}) do
    post = Blog.Posts.get_post(slug: slug)

    socket
    |> assign(:page_title, (post && post.title) || "Post Not Found")
    |> assign(:post, post)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path="/posts">
      <:aside>
        <Options.options />
        <Discord.presence presence={@presence} />
        <Viewers.counts site_count={@site_viewer_count} page_count={@page_viewer_count} />

        <Toc.toc
          headings={
            if @live_action == :show and is_struct(@post) and length(@post.headings || []) > 1,
              do: @post.headings,
              else: []
          }
          id="toc"
        />
      </:aside>

      <div id="posts-live-container" phx-hook=".ScrollToTop">
        <%= cond do %>
          <% @live_action == :index -> %>
            <Post.list
              posts={@posts}
              id="posts"
              all_tags={@all_tags}
              selected_tags={@selected_tags}
              search_query={@search_query}
            />
          <% @live_action == :show and is_struct(@post) -> %>
            <Post.full post={@post} />
          <% true -> %>
            <Bluescreen.bluescreen error={:post_not_found} href="/posts" />
        <% end %>
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".ScrollToTop">
        export default {
          mounted() {
            this.handleEvent("scroll-to-top", () => {
              setTimeout(() => {
                window.scrollTo({top: 0, behavior: "smooth"})
              }, 0)
            })
          }
        }
      </script>
    </Layouts.app>
    """
  end
end
