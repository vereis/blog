defmodule BlogWeb.PostsLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Bluescreen
  alias BlogWeb.Components.Post
  alias BlogWeb.Components.Tag

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")
    end

    all_tags = Blog.Tags.list_tags()

    socket =
      socket
      |> assign(:all_tags, all_tags)
      |> assign(:posts, [])

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    selected_tags = Tag.labels_from_params(params)
    socket = assign(socket, :selected_tags, selected_tags)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_info({:resource_reload, Blog.Posts.Post, _id}, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, %{})}
  end

  defp apply_action(socket, :index, _params) do
    posts = Blog.Posts.list_posts(tags: socket.assigns[:selected_tags], order_by: [desc: :published_at])

    socket
    |> assign(:page_title, "Posts")
    |> assign(:posts, posts)
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
          <Post.list
            posts={@posts}
            id="posts"
            all_tags={@all_tags}
            selected_tags={@selected_tags}
          />
        <% @live_action == :show and is_struct(@post) -> %>
          <Post.full post={@post} />
        <% true -> %>
          <Bluescreen.bluescreen error={:post_not_found} href="/posts" />
      <% end %>
    </Layouts.app>
    """
  end
end
