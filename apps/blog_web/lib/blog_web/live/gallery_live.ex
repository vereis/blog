defmodule BlogWeb.GalleryLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Bluescreen
  alias BlogWeb.Components.Gallery
  alias BlogWeb.Components.Post

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    test_post = Blog.Posts.get_post(slug: "test")
    posts = Blog.Posts.list_posts(order_by: [desc: :published_at])

    socket =
      socket
      |> assign(:test_post, test_post)
      |> assign(:posts, posts)
      |> assign(:empty_posts, [])

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
        <Post.list posts={@posts} empty={@posts == []} />
      </Gallery.item>

      <Gallery.item title="Post List - Empty State" description="Empty state when no posts exist">
        <Post.list posts={[]} empty={true} />
      </Gallery.item>
    </Layouts.app>
    """
  end
end
