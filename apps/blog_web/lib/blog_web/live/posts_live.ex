defmodule BlogWeb.PostsLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias Blog.Schema.FTS
  alias BlogWeb.Components.Bluescreen
  alias BlogWeb.Components.Discord
  alias BlogWeb.Components.Post
  alias BlogWeb.Components.Search
  alias BlogWeb.Components.TableOfContents
  alias BlogWeb.Components.Tag

  @base_url "/posts"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")
      Phoenix.PubSub.subscribe(Blog.PubSub, "discord:presence")
    end

    socket =
      socket
      |> assign(:all_tags, Blog.Tags.list_tags(having: :posts))
      |> assign(:posts, [])
      |> assign(:presence, Blog.Discord.get_presence())

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
  def handle_info({:resource_reload, Blog.Posts.Post, _id}, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, %{})}
  end

  @impl Phoenix.LiveView
  def handle_info({:presence_updated, presence}, socket) do
    {:noreply, assign(socket, :presence, presence)}
  end

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
    <Layouts.app flash={@flash}>
      <:aside>
        <Discord.presence presence={@presence} />

        <TableOfContents.toc
          headings={
            if @live_action == :show and is_struct(@post) and length(@post.headings || []) > 1,
              do: @post.headings,
              else: []
          }
          id={if @live_action == :show and @post, do: "toc-#{@post.slug}", else: "toc"}
        />
      </:aside>

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
    </Layouts.app>
    """
  end
end
