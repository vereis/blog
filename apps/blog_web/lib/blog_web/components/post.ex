defmodule BlogWeb.Components.Post do
  @moduledoc """
  Post-related components for displaying blog content.
  """
  use Phoenix.Component

  alias Blog.Posts.Post
  alias BlogWeb.Components.Badge
  alias BlogWeb.Components.Tag
  alias Phoenix.LiveView.LiveStream

  @doc """
  Renders a full blog post with metadata and content.

  Displays the post title, tags, publication date, reading time, and body content.
  The post body is expected to be pre-rendered HTML.
  """
  attr :post, Post, required: true

  def full(assigns) do
    ~H"""
    <article class="post">
      <header>
        <hgroup class="post-title">
          <Badge.badge id={@post.slug}>{@post.title}</Badge.badge>
          <Tag.list tags={@post.tags} />
        </hgroup>
        <time class="post-published" datetime={DateTime.to_iso8601(@post.published_at)}>
          {Calendar.strftime(@post.published_at, "%B %d, %Y")}
        </time>
        <p class="post-read-time">
          {reading_time_text(@post.reading_time_minutes)}
        </p>
      </header>
      <section class="post-body">
        {Phoenix.HTML.raw(@post.body)}
      </section>
    </article>
    """
  end

  @doc """
  Renders a list of posts with optional loading state.

  Displays post items, loading skeletons, or empty state based on the provided attributes.

  ## Attributes

    * `posts` - List of Post structs to display
    * `loading` - Boolean indicating if posts are being loaded (default: false)
    * `empty` - Boolean indicating if the list is empty (default: false)
    * `id` - DOM ID for the list (default: "posts")
    * `title` - Optional title to display above the list (default: "All Posts")

  ## Examples

      # In your LiveView mount:
      def mount(_params, _session, socket) do
        posts = Blog.Posts.list_posts()
        {:ok, assign(socket, posts: posts, loading: false, posts_empty: posts == [])}
      end

      # In your template with regular assigns:
      <Post.list posts={@posts} loading={@loading} empty={@posts_empty} />

      # With LiveView streams:
      def mount(_params, _session, socket) do
        posts = Blog.Posts.list_posts()
        
        socket = 
          socket
          |> assign(:posts_empty, posts == [])
          |> stream(:posts, Enum.with_index(posts, 1))
        
        {:ok, socket}
      end
      
      <Post.list posts={@streams.posts} empty={@posts_empty} id="posts-stream" />
  """
  attr :posts, :any, default: [], doc: "List of Post structs or LiveView stream"
  attr :loading, :boolean, default: false
  attr :empty, :boolean, default: false
  attr :id, :string, default: "posts"
  attr :title, :string, default: "All Posts"
  attr :rest, :global, doc: "Additional HTML attributes to add to the list element"

  def list(assigns) do
    ~H"""
    <section>
      <Badge.badge id={"#{@id}-title"}>{@title}</Badge.badge>
      <ol
        id={@id}
        class={["posts-list", @loading && "posts-loading"]}
        phx-update={if @loading or @empty, do: nil, else: phx_update(@posts)}
        aria-busy={if @loading, do: "true", else: nil}
        {@rest}
      >
        <%= if @loading do %>
          <.skeleton :for={_ <- 1..5} />
        <% else %>
          <%= if @empty do %>
            <li class="posts-list-empty">
              No posts yet. Check back soon!
            </li>
          <% else %>
            <.item
              :for={{dom_id, {post, index}} <- normalize_posts(@posts)}
              id={dom_id}
              post={post}
              index={index}
            />
          <% end %>
        <% end %>
      </ol>
    </section>
    """
  end

  defp skeleton(assigns) do
    ~H"""
    <li class="post-skeleton" aria-busy="true" aria-label="Loading post">
      <article>
        <div class="post-header">
          <span class="skeleton-text skeleton-index"></span>
          <div class="post-content">
            <span class="skeleton-text skeleton-title"></span>
            <span class="skeleton-text skeleton-meta"></span>
          </div>
        </div>
      </article>
    </li>
    """
  end

  defp item(assigns) do
    ~H"""
    <li id={@id} class="post-item">
      <article>
        <div class="post-header">
          <span class="post-index">#{@index}</span>
          <div class="post-content">
            <h2 class="post-title">
              <.link patch={"/posts/#{@post.slug}"} aria-label={"Read post: #{@post.title}"}>
                {@post.title}
              </.link>
            </h2>
            <div class="post-meta">
              <time datetime={DateTime.to_iso8601(@post.published_at)}>
                {Calendar.strftime(@post.published_at, "%b %d, %Y")}
              </time>
              <span class="post-meta-sep">|</span>
              <span class="post-read-time">~{@post.reading_time_minutes} min</span>
              <span :if={@post.tags != []} class="post-meta-sep">|</span>
              <Tag.list :if={@post.tags != []} tags={@post.tags} />
            </div>
          </div>
        </div>
      </article>
    </li>
    """
  end

  defp phx_update(%LiveStream{}), do: "stream"
  defp phx_update(_), do: nil

  defp normalize_posts(%LiveStream{} = stream) do
    stream
  end

  defp normalize_posts(posts) when is_list(posts) do
    posts
    |> Enum.with_index(1)
    |> Enum.map(fn {post, index} ->
      {"post-#{post.id}", {post, index}}
    end)
  end

  defp reading_time_text(0), do: "Less than 1 minute read"
  defp reading_time_text(1), do: "Approx. 1 minute read"
  defp reading_time_text(minutes), do: "Approx. #{minutes} minutes read"
end
