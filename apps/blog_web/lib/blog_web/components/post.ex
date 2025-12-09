defmodule BlogWeb.Components.Post do
  @moduledoc """
  Post-related components for displaying blog content.
  """
  use Phoenix.Component

  alias Blog.Posts.Post

  @doc """
  Renders a full blog post with metadata and content.

  Displays the post title, tags, publication date, reading time, and body content.
  The post body is expected to be pre-rendered HTML.
  """
  attr :post, Post, required: true

  def full(assigns) do
    ~H"""
    <article class="post">
      <header class="post-metadata">
        <hgroup class="post-title">
          <h1 id={@post.slug}>{@post.title}</h1>
          <nav :if={@post.tags not in [nil, []]} class="tags" aria-label="Post tags">
            <a :for={tag <- @post.tags} href="#" class="tag">{"##{tag.label}"}</a>
          </nav>
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

  defp reading_time_text(0), do: "Less than 1 minute read"
  defp reading_time_text(1), do: "Approx. 1 minute read"
  defp reading_time_text(minutes), do: "Approx. #{minutes} minutes read"
end
