defmodule BlogWeb.BlogLive do
  @moduledoc false
  use Phoenix.LiveView
  use BlogWeb, :verified_routes

  import BlogWeb.CoreComponents, only: [input: 1]

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

    socket =
      socket
      |> assign_new(:is_release?, fn -> :code.get_mode() == :embedded end)
      |> assign_new(:posts, fn -> Posts.list_posts(order_by: [desc: :published_at]) end)
      |> assign_new(:post, fn -> Posts.get_post(slug: params["slug"] || "hello_world") end)
      |> assign_new(:projects, fn -> @projects end)
      |> assign_new(:tag, fn -> nil end)
      |> assign_new(:search, fn -> %{} end)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(:post_reload, socket) do
    socket =
      socket
      |> assign(:posts, Posts.list_posts(order_by: [desc: :published_at]))
      |> assign(:post, Posts.get_post(id: socket.assigns.post.id))

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("home", _params, socket) do
    socket = assign(socket, :post, Posts.get_post(1))
    {:noreply, push_patch(socket, to: ~p"/")}
  end

  @impl Phoenix.LiveView
  def handle_event("projects", _params, socket) do
    socket = socket |> assign(:tag, nil) |> assign(:post, nil)
    {:noreply, push_patch(socket, to: ~p"/projects")}
  end

  @impl Phoenix.LiveView
  def handle_event("posts", _params, socket) do
    socket = socket |> assign(:tag, nil) |> assign(:post, nil)
    {:noreply, push_patch(socket, to: ~p"/posts")}
  end

  @impl Phoenix.LiveView
  def handle_event("post", %{"post" => post}, socket) do
    socket = assign(socket, :post, Posts.get_post(slug: post))
    {:noreply, push_patch(socket, to: ~p"/posts/#{post}")}
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
    socket = assign(socket, :posts, Posts.list_posts(search: search_term))
    {:noreply, socket}
  end

  def handle_event("search", _params, socket) do
    socket = assign(socket, :posts, Posts.list_posts())
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="layout">
      <header>
        <span class="button-container">
          <.button phx-click="home">
            root@vereis.com ~
            <blink>█</blink>
          </.button>
        </span>
        <span class="button-container">
          <.button phx-click="posts">blog</.button>
          <.button phx-click="projects">projects</.button>
          <label class="button">
            crt <input id="crtFilter" phx-click={JS.dispatch("toggle-crt-filter")} type="checkbox" />
          </label>
        </span>
      </header>

      <%= if is_struct(@post) do %>
        <aside aria-label="Table of contents" class="table-of-contents-container">
          <p><strong>Table of Contents</strong></p>
          <%= for {header, index} <- Enum.with_index(@post.headings) do %>
            <a
              data-level={header.level}
              href={header.link}
              class={if index == 0, do: "active", else: ""}
            >
              <%= header.title %>
            </a>
          <% end %>
        </aside>
      <% end %>

      <%= if @live_action == :list_projects do %>
        <main>
          <div>
            <h1>
              All Projects <%= if @tag, do: "(##{@tag})", else: "" %>
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
              <span>search :: ~ >></span>
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
                    <%= "#" <> tag.label %>
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
                <div class="project-id"><%= "##{idx}" %></div>
                <div class="project-title-container">
                  <a class="project-name" href={project.url}>
                    <%= project.name %>
                  </a>
                  <p class="project-description"><%= project.description %></p>
                </div>
                <div class="tags">
                  <%= for tag <- project.tags do %>
                    <span class="tag" phx-click="proj-tag" phx-value-tag={tag.label}>
                      <%= "#" <> tag.label %>
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
              Blog Posts <%= if @tag, do: "(##{@tag})", else: "" %>
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

          <.form class="component-container" for={@search} phx-change="search">
            <label class="search-container hidden">
              <span>search :: ~ >></span>
              <.input
                field={@search[:value]}
                name="search"
                value=""
                type="text"
                size="1"
                placeholder=""
              />
            </label>

            <div>
              tags:
              <div class="tags">
                <%= for tag <- Enum.flat_map(@posts, & &1.tags) |> Enum.uniq() |> Enum.sort() do %>
                  <.button phx-click="tag" phx-value-tag={tag.label}>
                    <%= "#" <> tag.label %>
                  </.button>
                <% end %>
                <%= if @tag do %>
                  <a phx-click="posts">(clear)</a>
                <% end %>
              </div>
            </div>
          </.form>

          <div class="posts">
            <%= for post <- @posts, is_nil(@tag) or Enum.any?(post.tags, & &1.label == @tag), not @is_release? or not post.is_draft do %>
              <div class="post" phx-click="post" phx-value-post={post.slug}>
                <div class="post-id"><%= "##{post.id}" %></div>
                <div class="post-title-container">
                  <div class="post-title"><%= post.title %></div>
                  <div class="post-reading-time">
                    <%= Calendar.strftime(post.published_at, "%B %d %Y, %H:%M:%S") %>
                  </div>
                </div>
                <div class="tags">
                  <%= for tag <- post.tags do %>
                    <span class="tag" phx-click="tag" phx-value-tag={tag.label}>
                      <%= "#" <> tag.label %>
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </main>
      <% end %>

      <%= if @live_action in [:show_post, :home] do %>
        <main>
          <div class="post-metadata">
            <div class="post-title">
              <h1 id={hd(@post.headings).id}><%= @post.title %></h1>
              <div class="tags">
                <%= for tag <- @post.tags do %>
                  <.button phx-click="tag" phx-value-tag={tag.label}>
                    <%= "#" <> tag.label %>
                  </.button>
                <% end %>
              </div>
            </div>
            <div class="post-published">
              <%= Calendar.strftime(@post.published_at, "%B %d %Y, %H:%M:%S") %>
            </div>
            <div class="post-read-time">
              Approx. <%= @post.reading_time_minutes %> minute read
            </div>
          </div>

          <nav class="table-of-contents-container">
            <p><strong>Table of Contents</strong></p>
            <%= for header <- @post.headings do %>
              <a data-level={header.level} href={header.link}><%= header.title %></a>
            <% end %>
          </nav>

          <%= {:safe, @post.body} %>
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

  attr(:href, :string, default: nil)
  slot(:inner_block, required: true)
  attr(:rest, :global, include: ~w(disabled form name value))

  def button(assigns) do
    ~H"""
    <a {@rest} href={@href}><%= render_slot(@inner_block) %></a>
    """
  end
end
