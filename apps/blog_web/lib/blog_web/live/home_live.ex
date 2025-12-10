defmodule BlogWeb.HomeLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Post

  @slug "hello-world"

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")
    end

    post = load_post(params)

    {:ok, assign(socket, :post, post)}
  end

  defp load_post(%{"_debug" => "empty"}), do: nil

  defp load_post(%{"_debug" => "slow"}) do
    Process.sleep(5000)
    Blog.Posts.get_post(slug: @slug)
  end

  defp load_post(_params), do: Blog.Posts.get_post(slug: @slug)

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
        <.bluescreen error={nil}>
          An error has occurred. To continue:

          Press <a href="/">Enter or Click</a> to return to the blog, or

          Press CTRL+ALT+DEL to restart your computer. If you do this,
          you will lose any unsaved information in all open applications.

          Error: No blog post found
        </.bluescreen>
      <% end %>
    </Layouts.app>
    """
  end
end
