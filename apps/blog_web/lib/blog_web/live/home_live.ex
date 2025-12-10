defmodule BlogWeb.HomeLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Bluescreen
  alias BlogWeb.Components.Post

  @slug "hello-world"

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")
    end

    if params["_debug"] == "slow" do
      Process.sleep(5000)
    end

    {:ok,
     assign(
       socket,
       :post,
       (params["_debug"] != "empty" && Blog.Posts.get_post(slug: @slug)) || nil
     )}
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
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <%= if @post do %>
        <Post.full post={@post} />
      <% else %>
        <Bluescreen.bluescreen error={:post_not_found} href="/" />
      <% end %>
    </Layouts.app>
    """
  end
end
