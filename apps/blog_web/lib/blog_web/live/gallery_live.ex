defmodule BlogWeb.GalleryLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Gallery
  alias BlogWeb.Components.Post

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    about_post = Blog.Posts.get_post(slug: "about")
    {:ok, assign(socket, :about_post, about_post)}
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
        <Post.full :if={@about_post} post={@about_post} />
        <p :if={!@about_post} class="error">
          No "about" post found. Make sure to import posts first.
        </p>
      </Gallery.item>
    </Layouts.app>
    """
  end
end
