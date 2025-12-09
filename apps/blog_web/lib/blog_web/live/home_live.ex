defmodule BlogWeb.HomeLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Post

  @slug "hello-world"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")
    end

    socket =
      assign_async(socket, :post, fn ->
        {:ok, %{post: Blog.Posts.get_post(slug: @slug)}}
      end)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:resource_reload, Blog.Posts.Post, changed_id}, socket) do
    current_post_id =
      case socket.assigns.post do
        %{result: %{id: id}} -> id
        _other -> nil
      end

    socket =
      if current_post_id == changed_id do
        assign_async(socket, :post, fn ->
          {:ok, %{post: Blog.Posts.get_post(slug: @slug)}}
        end)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.async_result :let={post} assign={@post}>
        <:loading>
          <div class="loading">
            <.icon name="spinner" class="icon-spin" />
            <span>Loading...</span>
          </div>
        </:loading>
        <:failed :let={_reason}>
          <div class="error">
            <.icon name="error" />
            <span>Failed to load content. Please try again later.</span>
          </div>
        </:failed>
        <%= if post do %>
          <Post.full post={post} />
        <% else %>
          <div class="empty">
            <.icon name="info" />
            <span>No content available yet.</span>
          </div>
        <% end %>
      </.async_result>
    </Layouts.app>
    """
  end
end
