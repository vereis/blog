defmodule BlogWeb.GalleryLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Bluescreen
  alias BlogWeb.Components.EmptyState
  alias BlogWeb.Components.Gallery
  alias BlogWeb.Components.Post
  alias BlogWeb.Components.Project
  alias BlogWeb.Components.Search
  alias BlogWeb.Components.Tag

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    test_post = Blog.Posts.get_post(slug: "test")
    posts = Blog.Posts.list_posts(order_by: [desc: :published_at])
    projects = Blog.Projects.list_projects(order_by: [desc: :inserted_at])
    all_tags = Blog.Tags.list_tags()

    socket =
      socket
      |> assign(:test_post, test_post)
      |> assign(:posts, posts)
      |> assign(:empty_posts, [])
      |> assign(:projects, projects)
      |> assign(:all_tags, all_tags)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    selected_tags = Tag.labels_from_params(params)
    {:noreply, assign(socket, :selected_tags, selected_tags)}
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
        <div id="gallery-flash-group" class="flash-group" aria-live="polite">
          <.flash kind={:info} title="Info Flash">
            This is an informational message.
          </.flash>
          <.flash kind={:error} title="Error Flash">
            This is an error message.
          </.flash>
        </div>
      </Gallery.item>

      <Gallery.item title="Navigation" description="Site navigation component">
        <.navbar />
      </Gallery.item>

      <Gallery.item title="Search Filter - Empty" description="Text search filter with FTS support">
        <Search.input value="" base_url="/gallery" placeholder="(Example && Query) Or Search" />
      </Gallery.item>

      <Gallery.item
        title="Search Filter - With Value"
        description="Search filter with active query"
      >
        <Search.input
          value="elixir AND phoenix"
          base_url="/gallery"
          placeholder="(Example && Query) Or Search"
        />
      </Gallery.item>

      <Gallery.item
        title="Tag Filter (Interactive)"
        description="Tag filter component with multi-select - click tags to test!"
      >
        <Tag.filter tags={@all_tags} base_url="/gallery" selected_tags={@selected_tags} />
      </Gallery.item>

      <Gallery.item
        title="Tag Filter - Empty State"
        description="Tag filter when no tags are available"
      >
        <Tag.filter tags={[]} base_url="/gallery" selected_tags={[]} />
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
        title="Empty State - Block"
        description="Terminal-style block empty state with diagonal backslash hatching pattern"
      >
        <EmptyState.block>
          No content found. Check back later!
        </EmptyState.block>
      </Gallery.item>

      <Gallery.item
        title="Empty State - Block with Link"
        description="Block empty state with navigation link"
      >
        <EmptyState.block>
          Nothing here yet. <.link navigate="/">Return home</.link> or browse the gallery instead!
        </EmptyState.block>
      </Gallery.item>

      <Gallery.item title="Empty State - Inline" description="Inline empty state for minor contexts">
        <p>
          Available tags:
          <EmptyState.inline>No tags available</EmptyState.inline>
        </p>
      </Gallery.item>

      <Gallery.item title="Post List - With Posts" description="Multiple posts in list view">
        <Post.list posts={@posts} all_tags={@all_tags} selected_tags={@selected_tags} />
      </Gallery.item>

      <Gallery.item title="Post List - Empty State" description="Empty state when no posts exist">
        <Post.list posts={[]} all_tags={@all_tags} selected_tags={@selected_tags} />
      </Gallery.item>

      <Gallery.item title="Project List - With Projects" description="Multiple projects in list view">
        <Project.list projects={@projects} all_tags={@all_tags} selected_tags={@selected_tags} />
      </Gallery.item>

      <Gallery.item
        title="Project List - Empty State"
        description="Empty state when no projects exist"
      >
        <Project.list projects={[]} all_tags={@all_tags} selected_tags={@selected_tags} />
      </Gallery.item>
    </Layouts.app>
    """
  end
end
