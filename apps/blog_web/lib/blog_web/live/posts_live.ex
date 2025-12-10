defmodule BlogWeb.PostsLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Bluescreen
  alias BlogWeb.Components.Post

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")
    end

    socket =
      socket
      |> assign(:loading, true)
      |> assign(:debug_params, Map.take(params, ["_debug"]))
      |> stream_configure(:posts, dom_id: fn {post, _index} -> "post-#{post.id}" end)
      |> stream(:posts, [])

    send(self(), :load_posts)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    socket = assign(socket, :debug_params, Map.take(params, ["_debug"]))
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_info(:load_posts, socket) do
    if socket.assigns.debug_params["_debug"] == "slow" do
      Process.sleep(5000)
    end

    socket =
      if socket.assigns.live_action == :index and socket.assigns.debug_params["_debug"] != "empty" do
        posts = Blog.Posts.list_posts(order_by: [desc: :published_at])
        stream(socket, :posts, Enum.with_index(posts, 1), reset: true)
      else
        socket
      end

    {:noreply, assign(socket, :loading, false)}
  end

  def handle_info({:resource_reload, Blog.Posts.Post, _id}, socket) do
    send(self(), :load_posts)
    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Posts")
  end

  defp apply_action(socket, :show, %{"slug" => slug}) do
    post = Blog.Posts.get_post(slug: slug)

    socket
    |> assign(:page_title, if(post, do: post.title, else: "Post Not Found"))
    |> assign(:post, post)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <%= cond do %>
        <% @live_action == :index -> %>
          <Post.list posts={@streams.posts} loading={@loading} id="posts" />
        <% @live_action == :show and is_struct(@post) -> %>
          <Post.full post={@post} />
        <% true -> %>
          <Bluescreen.bluescreen error={:post_not_found} href="/posts" />
      <% end %>
    </Layouts.app>
    """
  end
end
