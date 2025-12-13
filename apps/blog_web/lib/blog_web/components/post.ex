defmodule BlogWeb.Components.Post do
  @moduledoc """
  Post-related components for displaying blog content.
  """
  use Phoenix.Component

  alias Blog.Posts.Post
  alias BlogWeb.Components.Badge
  alias BlogWeb.Components.Tag
  alias Phoenix.LiveView.LiveStream

  @base_url "/posts"

  @doc """
  Renders a full blog post with metadata and content.

  Displays the post title, tags, publication date, reading time, and body content.
  The post body is expected to be pre-rendered HTML.
  """
  attr :post, Post, required: true

  def full(assigns) do
    assigns = assign(assigns, :base_url, @base_url)

    ~H"""
    <article class="post">
      <header>
        <hgroup class="post-title">
          <Badge.badge id={@post.slug}>{@post.title}</Badge.badge>
          <Tag.list tags={@post.tags} base_url={@base_url} selected_tags={[]} />
        </hgroup>
        <time
          :if={@post.published_at}
          class="post-published"
          datetime={DateTime.to_iso8601(@post.published_at)}
        >
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
    * `id` - DOM ID for the list (default: "posts")
    * `title` - Optional title to display above the list (default: "All Posts")

  ## Examples

      def mount(_params, _session, socket) do
        posts = Blog.Posts.list_posts()
        {:ok, assign(socket, posts: posts, loading: false)}
      end

      # In your template with regular assigns:
      <Post.list posts={@streams.posts} id="posts-stream" />
  """
  attr :posts, :any, default: [], doc: "List of Post structs or LiveView stream"
  attr :loading, :boolean, default: false
  attr :id, :string, default: "posts"
  attr :title, :string, default: "All Posts"
  attr :selected_tags, :list, default: []
  attr :rest, :global, doc: "Additional HTML attributes to add to the list element"

  def list(assigns) do
    assigns = assign(assigns, :base_url, @base_url)

    ~H"""
    <section>
      <Badge.badge id={"#{@id}-title"}>{@title}</Badge.badge>
      <%= cond do %>
        <% @loading -> %>
          <p id={"#{@id}-loading-text"} phx-hook=".ScrambleCount"><span data-count>0</span> items</p>
          <ol id={"#{@id}-loading"} class={["posts-list", "posts-loading"]} aria-busy="true" {@rest}>
            <.skeleton :for={_ <- 1..5} />
          </ol>
          <script :type={Phoenix.LiveView.ColocatedHook} name=".ScrambleCount">
            export default {
              mounted() {
                const span = this.el.querySelector('[data-count]');
                this.interval = setInterval(() => {
                  span.textContent = Math.floor(Math.random() * 10);
                }, 50);
              },
              destroyed() {
                clearInterval(this.interval);
              }
            }
          </script>
        <% match?(%LiveStream{inserts: []}, @posts) or @posts == [] -> %>
          <p>No items</p>
          <ol id={"#{@id}-empty"} class="posts-list" {@rest}>
            <li class="posts-list-empty">
              No posts yet. Check back soon!
            </li>
          </ol>
        <% true -> %>
          <p>{Enum.count(@posts)} items</p>
          <ol id={@id} class="posts-list" phx-update={phx_update(@posts)} {@rest}>
            <.item
              :for={{dom_id, {post, index}} <- normalize_posts(@posts)}
              id={dom_id}
              post={post}
              index={index}
              base_url={@base_url}
              selected_tags={@selected_tags}
            />
          </ol>
      <% end %>
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
            <span class="skeleton-text skeleton-excerpt"></span>
            <span class="skeleton-text skeleton-meta"></span>
          </div>
        </div>
      </article>
    </li>
    """
  end

  defp item(assigns) do
    published_at = assigns.post.published_at

    {formatted_date, datetime_iso} =
      if published_at do
        {Calendar.strftime(published_at, "%b %d, %Y"), DateTime.to_iso8601(published_at)}
      else
        {nil, nil}
      end

    assigns =
      assigns
      |> assign(:formatted_date, formatted_date)
      |> assign(:datetime_iso, datetime_iso)

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
            <div :if={@post.excerpt} class="post-excerpt">
              {Phoenix.HTML.raw(@post.excerpt)}
              <p>
                <.link patch={"/posts/#{@post.slug}"} aria-label={"Read post: #{@post.title}"}>
                  Continue Reading...
                </.link>
              </p>
            </div>
            <div class="post-meta">
              <time :if={@post.published_at} datetime={@datetime_iso}>{@formatted_date}</time>
              <Tag.list
                :if={@post.tags != []}
                tags={@post.tags}
                base_url={@base_url}
                selected_tags={@selected_tags}
              />
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
    |> Enum.map(fn {post, index} -> {"post-#{post.id}", {post, index}} end)
  end

  defp reading_time_text(0), do: "Less than 1 minute read"
  defp reading_time_text(1), do: "Approx. 1 minute read"
  defp reading_time_text(minutes), do: "Approx. #{minutes} minutes read"
end
