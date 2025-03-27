defmodule BlogWeb.BlogLive do
  @moduledoc false
  use Phoenix.LiveView
  use BlogWeb, :verified_routes
  alias Phoenix.LiveView.JS

  alias Blog.Posts

  # TODO: source these from some `Blog` context.
  @projects [
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
      tags: [%{label: "elixir"}, %{label: "ecto"}, %{label: "oban"}],
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
      tags: [%{label: "elixir"}, %{label: "ecto"}, %{label: "migrations"}],
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
  ]

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
    socket = assign(socket, :tag, nil)
    {:noreply, push_patch(socket, to: ~p"/projects")}
  end

  @impl Phoenix.LiveView
  def handle_event("posts", _params, socket) do
    socket = assign(socket, :tag, nil)
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
  def render(assigns) do
    ~H"""
    <div>
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

      <%= if @live_action == :list_projects do %>
        <main>
          <div>
            <h1>
              All Projects <%= if @tag, do: "tagged #{@tag}", else: "" %>
            </h1>
            <%= if @tag do %>
              <a phx-click="projects">(clear)</a>
            <% end %>
          </div>
          <div>
            <%= for project <- @projects, is_nil(@tag) or Enum.any?(project.tags, & &1.label == @tag) do %>
              <div class="project">
                <a class="project_name" href={project.url}>
                  &nbsp;<%= project.name %>
                </a>
                <div class="project_tags">
                  <%= for tag <- project.tags do %>
                    <span class="project_tag" phx-click="proj-tag" phx-value-tag={tag.label}>
                      <%= tag.label %>
                    </span>
                  <% end %>
                </div>
                <p class="project_description"><%= project.description %></p>
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
              <a class="show-all" phx-click="posts">x</a>
            <% end %>
          </div>
          <article>
            <p>
              Here are a collection of posts I've written about anything and everything that comes to mind.
            </p>
            <p>Views expressed are my own and do not represent the views of my employer.</p>
            <p>You can filter by tags or search for a specific post below.</p>
            <div class="metadata">
              <div>
                Tags:
                <div class="tags">
                  <%= for tag <- Enum.flat_map(@posts, & &1.tags) |> Enum.uniq() |> Enum.sort() do %>
                    <.button phx-click="tag" phx-value-tag={tag.label}>
                      <%= "#" <> tag.label %>
                    </.button>
                  <% end %>
                  <%= if @tag do %>
                    <a class="show-all" phx-click="posts">(clear)</a>
                  <% end %>
                </div>
              </div>
            </div>
          </article>
          <div class="posts">
            <%= for post <- @posts, is_nil(@tag) or Enum.any?(post.tags, & &1.label == @tag), not @is_release? or not post.is_draft do %>
              <div class="post" phx-click="post" phx-value-post={post.slug}>
                <div class="post_id"><%= "##{post.id}" %></div>
                <div class="post_title_container">
                  <div class="post_title"><%= post.title %></div>
                  <div class="post_reading_time">
                    <%= Calendar.strftime(post.published_at, "%B %d %Y, %H:%M:%S") %>
                  </div>
                </div>
                <div class="post_tags">
                  <%= for tag <- post.tags do %>
                    <span class="post_tag" phx-click="tag" phx-value-tag={tag.label}>
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
          <div>
            <%= if is_nil(@post) do %>
              <h1>Ut-oh !!</h1>
            <% else %>
              <h1><%= @post.title %></h1>
            <% end %>
          </div>
          <%= unless is_nil(@post) do %>
            <div class="metadata">
              <div>
                <div class="published">
                  <%= Calendar.strftime(@post.published_at, "%B %d %Y, %H:%M:%S") %>
                </div>
                <div class="tags">
                  <%= for tag <- @post.tags do %>
                    <.button phx-click="tag" phx-value-tag={tag.label}>
                      <%= "#" <> tag.label %>
                    </.button>
                  <% end %>
                </div>
              </div>
              <div class="read_time">
                Approx. <%= @post.reading_time_minutes %> minute read
              </div>
            </div>
          <% end %>

          <article>
            <%= if is_nil(@post) do %>
              <p>It looks like something went wrong!! (｡•́︿•̀｡)</p>
              <p>
                The requested post does not seem to exist. It may have been deleted, renamed, or archived.
                <br /><br />
                If this is a mistake please feel free to reach out and I'll fix it in a jiffy!
              </p>
              <p>
                <a phx-click="posts">See all posts&nbsp;</a> or <a phx-click="home">go home !!</a>
              </p>
            <% else %>
              <%= {:safe, @post.body} %>
            <% end %>
          </article>
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
