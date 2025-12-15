defmodule BlogWeb.GalleryLive do
  @moduledoc false
  use BlogWeb, :live_view

  alias BlogWeb.Components.Bluescreen
  alias BlogWeb.Components.Discord
  alias BlogWeb.Components.EmptyState
  alias BlogWeb.Components.Gallery
  alias BlogWeb.Components.Post
  alias BlogWeb.Components.Project
  alias BlogWeb.Components.Search
  alias BlogWeb.Components.TableOfContents
  alias BlogWeb.Components.Tag
  alias BlogWeb.Components.Viewers

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "discord:presence")

      # Track viewer on both site-wide and page-specific topics
      Viewers.track_viewer(self(), Viewers.site_topic(), socket.id)
      Viewers.track_viewer(self(), Viewers.page_topic(:gallery), socket.id)

      # Subscribe to viewer count updates
      Viewers.subscribe(Viewers.site_topic())
      Viewers.subscribe(Viewers.page_topic(:gallery))
    end

    test_post = Blog.Posts.get_post(slug: "test")
    posts = Blog.Posts.list_posts(order_by: [desc: :published_at])
    projects = Blog.Projects.list_projects(order_by: [desc: :inserted_at])
    all_tags = Blog.Tags.list_tags()
    presence = Blog.Discord.get_presence()

    socket =
      socket
      |> assign(:test_post, test_post)
      |> assign(:posts, posts)
      |> assign(:empty_posts, [])
      |> assign(:projects, projects)
      |> assign(:all_tags, all_tags)
      |> assign(:presence, presence)
      |> assign(:site_viewer_count, Viewers.count())
      |> assign(:page_viewer_count, Viewers.count(:gallery))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:presence_updated, presence}, socket) do
    {:noreply, assign(socket, :presence, presence)}
  end

  @impl Phoenix.LiveView
  def handle_info({:viewer_count_updated, topic, count}, socket) do
    cond do
      topic == Viewers.site_topic() ->
        {:noreply, assign(socket, :site_viewer_count, count)}

      topic == Viewers.page_topic(:gallery) ->
        {:noreply, assign(socket, :page_viewer_count, count)}

      true ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:viewer_joined, _topic}, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_info({:viewer_left, _topic}, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket}
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
      <:aside>
        <Discord.presence presence={@presence} />
        <Viewers.counts site_count={@site_viewer_count} page_count={@page_viewer_count} />

        <TableOfContents.toc headings={[]} id="toc" />
      </:aside>

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

      <Gallery.item
        title="Table of Contents"
        description="Navigation component for post headings with scrollspy"
      >
        <TableOfContents.toc
          headings={[
            %{title: "Introduction", link: "introduction", level: 1},
            %{title: "Getting Started", link: "getting-started", level: 2},
            %{title: "Installation", link: "installation", level: 3},
            %{title: "Configuration", link: "configuration", level: 3},
            %{title: "Usage", link: "usage", level: 2},
            %{title: "Basic Example", link: "basic-example", level: 3},
            %{title: "Advanced Features", link: "advanced-features", level: 2},
            %{title: "Conclusion", link: "conclusion", level: 1}
          ]}
          id="gallery-toc"
        />
      </Gallery.item>

      <Gallery.item
        title="Table of Contents - Empty State"
        description="TOC when no headings are available"
      >
        <TableOfContents.toc headings={[]} id="gallery-toc-empty" />
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
        <Post.list
          id="gallery-posts-with-data"
          posts={@posts}
          all_tags={@all_tags}
          selected_tags={@selected_tags}
        />
      </Gallery.item>

      <Gallery.item title="Post List - Empty State" description="Empty state when no posts exist">
        <Post.list
          id="gallery-posts-empty"
          posts={[]}
          all_tags={@all_tags}
          selected_tags={@selected_tags}
        />
      </Gallery.item>

      <Gallery.item title="Project List - With Projects" description="Multiple projects in list view">
        <Project.list
          id="gallery-projects-with-data"
          projects={@projects}
          all_tags={@all_tags}
          selected_tags={@selected_tags}
        />
      </Gallery.item>

      <Gallery.item
        title="Project List - Empty State"
        description="Empty state when no projects exist"
      >
        <Project.list
          id="gallery-projects-empty"
          projects={[]}
          all_tags={@all_tags}
          selected_tags={@selected_tags}
        />
      </Gallery.item>

      <Gallery.item
        title="Discord Presence - Online"
        description="User is online, no activity or spotify"
      >
        <Discord.presence
          id="gallery-discord-online"
          presence={
            %Blog.Discord.Presence{
              connected?: true,
              discord_user: %{"username" => "vereis"},
              discord_status: "online",
              activities: [],
              listening_to_spotify: false
            }
          }
        />
      </Gallery.item>

      <Gallery.item
        title="Discord Presence - Online with Activity"
        description="User is online and playing a game"
      >
        <Discord.presence
          id="gallery-discord-activity"
          presence={
            %Blog.Discord.Presence{
              connected?: true,
              discord_user: %{"username" => "vereis"},
              discord_status: "online",
              activities: [%{"name" => "Elixir"}],
              listening_to_spotify: false
            }
          }
        />
      </Gallery.item>

      <Gallery.item
        title="Discord Presence - Online with Spotify"
        description="User is online and listening to Spotify (no activity)"
      >
        <Discord.presence
          id="gallery-discord-spotify"
          presence={
            %Blog.Discord.Presence{
              connected?: true,
              discord_user: %{"username" => "vereis"},
              discord_status: "online",
              activities: [],
              listening_to_spotify: true,
              spotify: %{"song" => "Never Gonna Give You Up", "artist" => "Rick Astley"}
            }
          }
        />
      </Gallery.item>

      <Gallery.item
        title="Discord Presence - Online with Activity and Spotify"
        description="User is online, playing a game, and listening to Spotify"
      >
        <Discord.presence
          id="gallery-discord-full"
          presence={
            %Blog.Discord.Presence{
              connected?: true,
              discord_user: %{"username" => "vereis"},
              discord_status: "online",
              activities: [%{"name" => "Visual Studio Code"}],
              listening_to_spotify: true,
              spotify: %{"song" => "Lofi Beats", "artist" => "ChilledCow"}
            }
          }
        />
      </Gallery.item>

      <Gallery.item
        title="Discord Presence - Idle"
        description="User is idle with activity"
      >
        <Discord.presence
          id="gallery-discord-idle"
          presence={
            %Blog.Discord.Presence{
              connected?: true,
              discord_user: %{"username" => "vereis"},
              discord_status: "idle",
              activities: [%{"name" => "Phoenix LiveView"}],
              listening_to_spotify: false
            }
          }
        />
      </Gallery.item>

      <Gallery.item
        title="Discord Presence - Do Not Disturb"
        description="User is in do not disturb mode"
      >
        <Discord.presence
          id="gallery-discord-dnd"
          presence={
            %Blog.Discord.Presence{
              connected?: true,
              discord_user: %{"username" => "vereis"},
              discord_status: "dnd",
              activities: [%{"name" => "Deep Work"}],
              listening_to_spotify: true,
              spotify: %{"song" => "Focus Music", "artist" => "Study Vibes"}
            }
          }
        />
      </Gallery.item>

      <Gallery.item
        title="Discord Presence - Offline"
        description="User is disconnected"
      >
        <Discord.presence
          id="gallery-discord-offline"
          presence={%Blog.Discord.Presence{connected?: false}}
        />
      </Gallery.item>
    </Layouts.app>
    """
  end
end
