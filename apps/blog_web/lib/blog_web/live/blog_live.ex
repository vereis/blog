defmodule BlogWeb.BlogLive do
  @moduledoc false
  use BlogWeb, :live_view

  import BlogWeb.CoreComponents, only: [input: 1]

  alias Blog.Lanyard
  alias Blog.Posts
  alias Phoenix.LiveView.JS

  # TODO: source these from some `Blog` context.
  @projects Enum.reverse([
              %{
                name: "Neovim Config",
                tags: [%{label: "neovim"}, %{label: "lua"}],
                url: "https://github.com/vereis/nix-config/tree/master/modules/home/neovim/lua",
                description: """
                Personal Neovim configuration based on Lazy, with LSP support, Treesitter, and custom Lua plugins.
                """
              },
              %{
                name: "Nix Config",
                tags: [%{label: "nix"}, %{label: "nixos"}],
                url: "https://github.com/vereis/nix-config",
                description: """
                Personal Nix configuration utilizing flakes and building regularly for Windows (WSL), Linux, and MacOS.
                """
              },
              %{
                name: "Toggle",
                tags: [%{label: "elixir"}, %{label: "ecto"}],
                url: "https://github.com/vereis/toggle",
                description: """
                Minimalistic and stupid-simple Feature Flagging Library for Elixir, with cache support and hooking capabilities.
                """
              },
              %{
                name: "Cinema",
                tags: [%{label: "elixir"}],
                url: "https://github.com/vereis/cinema",
                description: """
                Framework for defining Incremental Materialized Views in raw Elixir and Ecto, with support for recursive/dependant views.
                """
              },
              %{
                name: "Sibyl",
                tags: [%{label: "elixir"}, %{label: "telemetry"}],
                url: "https://github.com/vetspire/sibyl",
                description: """
                Zero runtime cost telemetry and distributed tracing with custom plugins, library support, leveraging standard telemetry events.
                """
              },
              %{
                name: "Endo",
                tags: [%{label: "elixir"}, %{label: "ecto"}],
                url: "https://github.com/vetspire/endo",
                description: """
                Database reflection tool with fluent, composable API for Postgres and SQLite.
                """
              },
              %{
                name: "Ecto Middleware",
                tags: [%{label: "elixir"}, %{label: "ecto"}],
                url: "https://github.com/vereis/ecto_middleware",
                description: """
                Generic middleware implementation for Ecto, allowing for easy customization and extension of Ecto's standard Repo interface.
                """
              },
              %{
                name: "Ecto Hooks",
                tags: [%{label: "elixir"}, %{label: "ecto"}],
                url: "https://github.com/vereis/ecto_hooks",
                description: """
                Library which extends Ecto Schemas with the ability to automatically execute before or after hooks on Repo callbacks.
                """
              },
              %{
                name: "Ecto Model",
                tags: [%{label: "elixir"}, %{label: "ecto"}],
                url: "https://github.com/vetspire/ecto_model",
                description: """
                Collection of various Ecto extensions and utilities to make working with Ecto more enjoyable, including a query building abstraction and hooks.
                """
              },
              %{
                name: "Monarch",
                tags: [%{label: "elixir"}, %{label: "migrations"}],
                url: "https://hexdocs.pm/monarch/Monarch.html",
                description: """
                A simple Oban powered framework for defining and running long running, large data backfill tasks asynchronously across your cluster.
                """
              },
              %{
                name: "Jarlang",
                tags: [%{label: "erlang"}, %{label: "compiler"}],
                url: "https://github.com/vereis/jarlang",
                description: """
                (Archived) Erlang to ES5 compiler, written in Erlang and absolutely, definitely not suitable for production use.
                """
              },
              %{
                name: "Blog",
                tags: [%{label: "elixir"}, %{label: "liveview"}],
                url: "https://github.com/vereis/blog",
                description: """
                My personal blog and playground for Phoenix LiveView and other technologies.
                """
              }
            ])

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")
    Phoenix.PubSub.subscribe(Blog.PubSub, "image:reload")
    Phoenix.PubSub.subscribe(Blog.PubSub, "lanyard:presence")

    posts = Posts.list_posts(order_by: [desc: :published_at])
    post = Posts.get_post(slug: params["slug"] || "hello_world")

    socket =
      socket
      |> assign_new(:is_release?, fn -> :code.get_mode() == :embedded end)
      |> assign_new(:posts, fn -> posts end)
      |> assign_new(:post, fn -> post end)
      |> assign_new(:projects, fn -> @projects end)
      |> assign_new(:tag, fn -> nil end)
      |> assign_new(:search, fn -> %{} end)
      |> assign_new(:presence, fn -> Lanyard.get_presence() end)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:resource_reload, Blog.Resource.Post, _post_id}, socket) do
    posts = Posts.list_posts(order_by: [desc: :published_at])

    # Reload current post if viewing a specific post
    post =
      if socket.assigns.post do
        Posts.get_post(id: socket.assigns.post.id)
      else
        socket.assigns.post
      end

    socket =
      socket
      |> assign(:posts, posts)
      |> assign(:post, post)
      |> assign(:page_title, (post && post.title) || nil)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:resource_reload, Blog.Resource.Image, _image_id}, socket) do
    # For images, we might need to reload the current post if it contains images
    # For now, just reload the current post if we're viewing one
    post =
      if socket.assigns.post do
        Posts.get_post(id: socket.assigns.post.id)
      else
        socket.assigns.post
      end

    socket = assign(socket, :post, post)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:resource_reload, _resource_type, _id}, socket) do
    # Handle other resource types generically
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:presence_updated, presence}, socket) do
    {:noreply, assign(socket, :presence, presence)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("home", _params, socket) do
    post = Posts.get_post(1)

    {:noreply,
     socket
     |> assign(:post, post)
     |> assign(:page_title, (post && post.title) || nil)
     |> push_patch(to: ~p"/")}
  end

  @impl Phoenix.LiveView
  def handle_event("projects", _params, socket) do
    {:noreply,
     socket
     |> assign(:tag, nil)
     |> assign(:post, nil)
     |> assign(:page_title, "Projects")
     |> push_patch(to: ~p"/projects")}
  end

  @impl Phoenix.LiveView
  def handle_event("posts", _params, socket) do
    {:noreply,
     socket
     |> assign(:tag, nil)
     |> assign(:post, nil)
     |> assign(:page_title, "Blog Posts")
     |> push_patch(to: ~p"/posts")}
  end

  @impl Phoenix.LiveView
  def handle_event("post", %{"post" => post}, socket) do
    post = Posts.get_post(slug: post)

    {:noreply,
     socket
     |> assign(:post, post)
     |> assign(:page_title, (post && post.title) || nil)
     |> push_patch(to: ~p"/posts/#{post.slug}")}
  end

  @impl Phoenix.LiveView
  def handle_event("tag", %{"tag" => tag}, socket) do
    socket = assign(socket, :tag, tag)
    {:noreply, push_patch(socket, to: ~p"/posts")}
  end

  @impl Phoenix.LiveView
  def handle_event("proj-tag", %{"tag" => tag}, socket) do
    socket = assign(socket, :tag, tag)
    {:noreply, push_patch(socket, to: ~p"/projects")}
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"search" => search_term}, socket) when byte_size(search_term) > 0 do
    socket =
      assign(
        socket,
        :posts,
        Posts.list_posts(search: search_term, order_by: [desc: :published_at])
      )

    {:noreply, socket}
  end

  def handle_event("search", _params, socket) do
    socket = assign(socket, :posts, Posts.list_posts(order_by: [desc: :published_at]))
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="layout">
      <header>
        <span class="button-container">
          <.button phx-click="home">
            <.status_indicator presence={@presence} /> root@vereis.com ~
            <blink>█</blink>
          </.button>
        </span>
        <span class="button-container">
          <.button phx-click="posts">blog</.button>
          <.button phx-click="projects">projects</.button>
          <label class="button">
            <span>crt</span>
            <input id="crtFilter" phx-click={JS.dispatch("toggle-crt-filter")} type="checkbox" />
          </label>
        </span>
      </header>

      <aside aria-label="Navigation" class="aside-navigation">
        <.online_status_section presence={@presence} />
        <.listening_to_section presence={@presence} />

        <%= if @live_action in [:show_post, :home] and is_struct(@post) and @post.headings != [] do %>
          <div class="table-of-contents-container">
            <p><strong>Table of Contents</strong></p>
            <%= for {header, index} <- Enum.with_index(@post.headings) do %>
              <a
                data-level={header.level}
                href={header.link}
                class={if index == 0, do: "active", else: ""}
              >
                {header.title}
              </a>
            <% end %>
          </div>
        <% end %>
      </aside>

      <%= if @live_action == :list_projects do %>
        <main>
          <div>
            <h1>
              All Projects {if @tag, do: "(##{@tag})", else: ""}
            </h1>
            <%= if @tag do %>
              <a phx-click="projects">x</a>
            <% end %>
          </div>
          <p>
            Personal projects or open source contributions.
          </p>
          <blockquote>
            For a more complete list, check out <a href="https://github.com/vereis">my GitHub </a>
            profile.
          </blockquote>

          <h2>Index</h2>

          <div class="component-container">
            <label class="search-container hidden">
              <span>search:</span>
              <span class="input-container">
                <input
                  type="text"
                  onInput="this.parentNode.dataset.value = this.value"
                  size="1"
                  placeholder=""
                />
              </span>
            </label>

            <div>
              tags:
              <div class="tags">
                <%= for tag <- Enum.flat_map(@projects, & &1.tags) |> Enum.uniq() |> Enum.sort() do %>
                  <.button phx-click="proj-tag" phx-value-tag={tag.label}>
                    {"#" <> tag.label}
                  </.button>
                <% end %>
                <%= if @tag do %>
                  <a phx-click="projects">(clear)</a>
                <% end %>
              </div>
            </div>
          </div>

          <div class="projects">
            <%= for {project, idx} <- Enum.reverse(Enum.with_index(@projects)), is_nil(@tag) or Enum.any?(project.tags, & &1.label == @tag) do %>
              <div class="project">
                <div class="project-id">{"##{idx}"}</div>
                <div class="project-title-container">
                  <a class="project-name" href={project.url}>
                    {project.name}
                  </a>
                  <p class="project-description">{project.description}</p>
                </div>
                <div class="tags">
                  <%= for tag <- project.tags do %>
                    <span class="tag" phx-click="proj-tag" phx-value-tag={tag.label}>
                      {"#" <> tag.label}
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </main>
      <% end %>

      <%= if @live_action == :list_posts do %>
        <main>
          <div>
            <h1>
              Blog Posts {if @tag, do: "(##{@tag})", else: ""}
            </h1>
            <%= if @tag do %>
              <a phx-click="posts">x</a>
            <% end %>
          </div>
          <p>
            Personal blog posts, notes, and other ramblings.
          </p>

          <blockquote>
            Views expressed here or elsewhere online are my own and do not reflect the views of my employer.
          </blockquote>

          <h2>Index</h2>

          <.form class="component-container" for={@search} phx-change="search" phx-debounce="300">
            <label class="search-container">
              <span>search:</span>
              <.input
                field={@search[:value]}
                name="search"
                value=""
                type="text"
                size="1"
                placeholder=""
                phx-debounce="300"
              />
            </label>

            <% all_tags = Enum.flat_map(@posts, & &1.tags) |> Enum.uniq() |> Enum.sort() %>
            <%= if not Enum.empty?(all_tags) do %>
              <div>
                tags:
                <div class="tags">
                  <%= for tag <- all_tags do %>
                    <.button phx-click="tag" phx-value-tag={tag.label}>
                      {"#" <> tag.label}
                    </.button>
                  <% end %>
                  <%= if @tag do %>
                    <a phx-click="posts">(clear)</a>
                  <% end %>
                </div>
              </div>
            <% end %>
          </.form>

          <div class="posts">
            <% filtered_posts =
              Enum.filter(@posts, fn post ->
                (is_nil(@tag) or Enum.any?(post.tags, &(&1.label == @tag))) and
                  (not @is_release? or not post.is_draft)
              end) %>

            <%= if Enum.empty?(filtered_posts) do %>
              <blockquote class="warning" style="margin-top: 1ex;">
                <p><strong>Warning:</strong> No content found</p>
                <p><a href="/posts">Reset page</a></p>
              </blockquote>
            <% else %>
              <%= for post <- filtered_posts do %>
                <div class="post" phx-click="post" phx-value-post={post.slug}>
                  <div class="post-id">{"##{post.id}"}</div>
                  <div class="post-title-container">
                    <div class="post-title">{post.title}</div>
                    <div class="post-reading-time">
                      {Calendar.strftime(post.published_at, "%B %d %Y, %H:%M:%S")}
                    </div>
                  </div>
                  <div class="tags">
                    <%= for tag <- post.tags do %>
                      <span class="tag" phx-click="tag" phx-value-tag={tag.label}>
                        {"#" <> tag.label}
                      </span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </main>
      <% end %>

      <%= if @live_action in [:show_post, :home] and is_struct(@post) do %>
        <main>
          <div class="post-metadata">
            <div class="post-title">
              <h1 id={
                if @post.headings != [] and hd(@post.headings),
                  do: hd(@post.headings).id,
                  else: "post-title"
              }>
                {@post.title}
              </h1>
              <div class="tags">
                <%= for tag <- @post.tags do %>
                  <.button phx-click="tag" phx-value-tag={tag.label}>
                    {"#" <> tag.label}
                  </.button>
                <% end %>
              </div>
            </div>
            <div class="post-published">
              {Calendar.strftime(@post.published_at, "%B %d %Y, %H:%M:%S")}
            </div>
            <div class="post-read-time">
              Approx. {@post.reading_time_minutes} minute read
            </div>
          </div>
          {{:safe, @post.body}}
        </main>
      <% end %>

      <footer>
        <a class="end" href="#">
          <span>BACK</span>
        </a>
        <div class="button-container">
          <.button href="/rss">rss</.button>
          <.button href="https://github.com/vereis/blog">source code</.button>
        </div>
      </footer>
    </div>
    """
  end

  attr(:presence, :map, required: true)

  def status_indicator(%{presence: %Lanyard.Presence{} = _presence} = assigns) do
    {status, tooltip} =
      case assigns.presence do
        %Lanyard.Presence{connected?: true, discord_status: "online"} ->
          {"status-online", "Online"}

        %Lanyard.Presence{connected?: true, discord_status: "idle"} ->
          {"status-idle", "Idle"}

        %Lanyard.Presence{connected?: true, discord_status: "dnd"} ->
          {"status-dnd", "Do Not Disturb"}

        %Lanyard.Presence{connected?: true, discord_status: "offline"} ->
          {"status-offline", "Offline"}

        _disconnected ->
          {"status-disconnected", "Disconnected"}
      end

    assigns = assign(assigns, status: status, tooltip: tooltip)

    ~H"""
    <span class={["status-indicator", @status]} data-tooltip={@tooltip}></span>
    """
  end

  attr(:href, :string, default: nil)
  slot(:inner_block, required: true)
  attr(:rest, :global, include: ~w(disabled form name value))

  def button(assigns) do
    ~H"""
    <a {@rest} href={@href}>{render_slot(@inner_block)}</a>
    """
  end

  attr(:presence, :map, required: true)

  def online_status_section(assigns) do
    ~H"""
    <div class="presence-section online-status-section">
      <p><strong>Online Status</strong> <.status_indicator presence={@presence} /></p>
      <%= if @presence.connected? do %>
        <p class="presence-content">
          {Enum.find(@presence.activities || [], %{}, &(&1["id"] == "custom"))["state"]}
        </p>
      <% end %>
    </div>
    """
  end

  attr(:presence, :map, required: true)

  def listening_to_section(assigns) do
    ~H"""
    <div class="presence-section">
      <p><strong>Listening To</strong></p>
      <%= if @presence.connected? and @presence.listening_to_spotify and @presence.spotify do %>
        <p class="presence-content">{@presence.spotify["song"]} - {@presence.spotify["artist"]}</p>
      <% else %>
        <p class="presence-content">N/A</p>
      <% end %>
    </div>
    """
  end
end
