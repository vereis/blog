defmodule BlogWeb.GalleryLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Bluescreen
  alias BlogWeb.Components.Gallery
  alias BlogWeb.Components.Post
  alias BlogWeb.Components.Project
  alias BlogWeb.Components.Tag

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    test_post = Blog.Posts.get_post(slug: "test")
    posts = Blog.Posts.list_posts(order_by: [desc: :published_at])
    projects = Blog.Projects.list_projects(order_by: [desc: :inserted_at])

    socket =
      socket
      |> assign(:test_post, test_post)
      |> assign(:posts, posts)
      |> assign(:empty_posts, [])
      |> assign(:projects, projects)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Component Gallery</h1>
      <p>Preview of available components and their variants.</p>

      <Gallery.item title="Icons" description="ASCII/Unicode icons for terminal aesthetic">
        <div class="icon-gallery">
          <div class="icon-item">
            <.icon name="info" />
            <code>info</code>
          </div>
          <div class="icon-item">
            <.icon name="error" />
            <code>error</code>
          </div>
          <div class="icon-item">
            <.icon name="close" />
            <code>close</code>
          </div>
          <div class="icon-item">
            <.icon name="spinner" class="icon-spin" />
            <code>spinner</code>
          </div>
        </div>
      </Gallery.item>

      <Gallery.item title="Flash Messages" description="Flash notifications for user feedback">
        <.flash kind={:info} title="Info Flash">
          This is an informational message.
        </.flash>
        <.flash kind={:error} title="Error Flash">
          This is an error message.
        </.flash>
      </Gallery.item>

      <Gallery.item title="Navigation" description="Site navigation component">
        <.navbar />
      </Gallery.item>

      <Gallery.item title="Tags" description="Tag components with normal and active states">
        <div style="display: flex; flex-direction: column; gap: var(--space-line);">
          <div>
            <p style="margin-block-end: var(--space-1); color: var(--color-fg-secondary);">
              Normal tags (clickable, hover to see effect):
            </p>
            <nav class="tags" aria-label="Tags">
              <Tag.single tag="elixir" href="#" />
              <Tag.single tag="phoenix" href="#" />
              <Tag.single tag="liveview" href="#" />
              <Tag.single tag="webdev" href="#" />
            </nav>
          </div>

          <div>
            <p style="margin-block-end: var(--space-1); color: var(--color-fg-secondary);">
              Active/selected tags (with .tag-active class):
            </p>
            <nav class="tags" aria-label="Tags">
              <Tag.single tag="elixir" href="#" class="tag-active" />
              <Tag.single tag="phoenix" href="#" class="tag-active" />
              <Tag.single tag="liveview" href="#" />
              <Tag.single tag="webdev" href="#" />
            </nav>
          </div>

          <div>
            <p style="margin-block-end: var(--space-1); color: var(--color-fg-secondary);">
              Tag filter bar (active filters with clear buttons):
            </p>
            <nav class="tag-filter" aria-label="Active filters">
              <span class="tag-filter-label">Filtering by:</span>
              <Tag.single tag="elixir" href="#" class="tag-active" />
              <Tag.single tag="phoenix" href="#" class="tag-active" />
              <.link href="#" class="tag-filter-clear">Clear all</.link>
            </nav>
          </div>
        </div>
      </Gallery.item>

      <Gallery.item title="Post Component" description="Full post rendering with metadata">
        <Post.full :if={@test_post} post={@test_post} />
        <p :if={!@test_post} class="error">
          No "test" post found. Make sure to import posts first.
        </p>
      </Gallery.item>

      <Gallery.item title="Bluescreen" description="Windows 95-style error screen">
        <Bluescreen.bluescreen error={nil} href="/gallery" />
      </Gallery.item>

      <Gallery.item
        title="Post List - Loading State"
        description="Loading state with skeleton placeholders"
      >
        <Post.list posts={[]} loading={true} />
      </Gallery.item>

      <Gallery.item title="Post List - With Posts" description="Multiple posts in list view">
        <Post.list posts={@posts} />
      </Gallery.item>

      <Gallery.item title="Post List - Empty State" description="Empty state when no posts exist">
        <Post.list posts={[]} />
      </Gallery.item>

      <Gallery.item
        title="Project List - Loading State"
        description="Loading state with skeleton placeholders"
      >
        <Project.list projects={[]} loading={true} />
      </Gallery.item>

      <Gallery.item title="Project List - With Projects" description="Multiple projects in list view">
        <Project.list projects={@projects} />
      </Gallery.item>

      <Gallery.item
        title="Project List - Empty State"
        description="Empty state when no projects exist"
      >
        <Project.list projects={[]} />
      </Gallery.item>
    </Layouts.app>
    """
  end
end
