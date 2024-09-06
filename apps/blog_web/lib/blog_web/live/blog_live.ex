defmodule BlogWeb.BlogLive do
  @moduledoc false
  use Phoenix.LiveView
  use BlogWeb, :verified_routes

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
    <div class="text-white max-w-3xl mx-auto space-y-8 p-2 md:p-6 border-x-[1px] border-white/25 min-h-screen">
      <header class="flex justify-between font-mono">
        <span>
          <.button pink={true} phx-click="home">vereis (⁠◠⁠‿⁠・⁠)⁠—⁠☆</.button>
        </span>
        <span>
          <.button mobile?={false} href="/rss">rss</.button>
          <.button phx-click="posts">posts</.button>
          <.button phx-click="projects">projs</.button>
          <.button mobile?={false} href="https://github.com/vereis/blog">&lt;/&gt;</.button>
        </span>
      </header>

      <%= if @live_action == :list_projects do %>
        <main class="px-2 md:px-4 mx-auto">
          <div>
            <h1 class="px-[1rem] bg-blue-700 inline-block mb-4">
              All Projects <%= if @tag, do: "tagged #{@tag}", else: "" %>
            </h1>
            <%= if @tag do %>
              <a class="cursor-pointer underline italic" phx-click="projects">(clear)</a>
            <% end %>
          </div>
          <div class="space-y-4">
            <%= for project <- @projects, is_nil(@tag) or Enum.any?(project.tags, & &1.label == @tag) do %>
              <div class="cursor-pointer grid grid-cols-12">
                <a
                  href={project.url}
                  class="before:content-['#'] before:-mr-2 text-green-400 col-start-1 col-end-7 hover:underline"
                >
                  &nbsp;<%= project.name %>
                </a>
                <div class="col-start-7 col-end-13 text-right">
                  <%= for tag <- project.tags do %>
                    <span
                      class="cursor-pointer no-underline px-1 hover:bg-pink-300 hover:text-black inline-block"
                      phx-click="proj-tag"
                      phx-value-tag={tag.label}
                    >
                      <%= tag.label %>
                    </span>
                  <% end %>
                </div>
                <p class="col-start-1 col-end-13 text-gray-400"><%= project.description %></p>
              </div>
            <% end %>
          </div>
          <span class="inline-block bg-gray-300 my-4 px-2 text-gray-600">(END)</span>
        </main>
      <% end %>

      <%= if @live_action == :list_posts do %>
        <main class="px-2 md:px-4 mx-auto">
          <div>
            <h1 class="px-[1rem] bg-blue-700 inline-block mb-4">
              All Posts <%= if @tag, do: "tagged #{@tag}", else: "" %>
            </h1>
            <%= if @tag do %>
              <a class="cursor-pointer underline italic" phx-click="posts">(clear)</a>
            <% end %>
          </div>
          <%= for post <- @posts, is_nil(@tag) or Enum.any?(post.tags, & &1.label == @tag), not @is_release? or not post.is_draft do %>
            <div phx-click="post" phx-value-post={post.slug} class="cursor-pointer grid grid-cols-12">
              <div class="before:content-['#'] before:-mr-2 text-green-400 col-start-1 col-end-2">
                <%= post.id %>
              </div>
              <div class="col-start-2 md:col-end-7 col-end-10 hover:underline"><%= post.title %></div>
              <div class="hidden md:block md:col-start-7 md:col-end-11 md:text-right">
                <%= for tag <- post.tags do %>
                  <span
                    class="cursor-pointer no-underline px-1 hover:bg-pink-300 hover:text-black inline-block"
                    phx-click="tag"
                    phx-value-tag={tag.label}
                  >
                    <%= tag.label %>
                  </span>
                <% end %>
              </div>
              <div class="col-start-10 md:col-start-11 col-end-13 text-right">
                <%= DateTime.to_date(post.published_at) %>
              </div>
              <div class="md:hidden col-start-2 col-end-13 text-gray-400">
                Tagged:
                <%= for tag <- post.tags do %>
                  <span
                    class="cursor-pointer no-underline px-1 hover:bg-pink-300 hover:text-black inline-block"
                    phx-click="tag"
                    phx-value-tag={tag.label}
                  >
                    <%= tag.label %>
                  </span>
                <% end %>
              </div>
            </div>
          <% end %>
          <span class="inline-block bg-gray-300 my-4 px-2 text-gray-600">(END)</span>
        </main>
      <% end %>

      <%= if @live_action in [:show_post, :home] do %>
        <main class="px-2 md:px-4 mx-auto">
          <div class="flex justify-between items-center">
            <%= if is_nil(@post) do %>
              <h1 class="px-[1rem] bg-blue-700 inline-block">Ut-oh !!</h1>
            <% else %>
              <h1 class="px-[1rem] bg-blue-700 inline-block"><%= @post.title %></h1>
              <div class="hidden md:flex flex flex-row-reverse items-center -mr-2">
                <%= for tag <- @post.tags do %>
                  <.button class="px-2" phx-click="tag" phx-value-tag={tag.label}>
                    <%= tag.label %>
                  </.button>
                <% end %>
                Tagged:&nbsp
              </div>
            <% end %>
          </div>

              <div class="flex md:hidden flex items-center text-gray-400">
                Tagged:&nbsp
                <%= for tag <- @post.tags do %>
                  <.button class="px-2" phx-click="tag" phx-value-tag={tag.label}>
                    <%= tag.label %>
                  </.button>
                <% end %>
              </div>

          <%= unless is_nil(@post) do %>
            <div class="hidden md:flex flex-row-reverse text-gray-400 my-[1px]">
              Published <%= DateTime.to_date(@post.published_at) %> @ <%= DateTime.to_time(
                @post.published_at
              ) %>
            </div>
            <div class="hidden md:flex flex-row-reverse -mt-1 text-gray-400">
              Approx. <%= @post.reading_time_minutes %> minutes
            </div>
          <% end %>

          <article class="
            prose prose-mono max-w-none
            selection:bg-pink-300 selection:text-pink-900
            my-4

            --headings
            prose-headings:text-base prose-headings:mb-4 prose-headings:mt-0 prose-headings:text-blue-500 prose-headings:inline-block
            prose-h1:text-base prose-h1:px-2 prose-h1:bg-blue-500 prose-h1:text-white prose-h1:-mb-2
            prose-h2:before:content-['##']
            prose-h3:before:content-['###']
            prose-h4:before:content-['####']
            prose-h5:before:content-['#####']
            prose-h6:before:content-['######']

            --code-blocks
            prose-code:text-base
            prose-code:outline-slate-800 prose-code:outline prose-code:outline-1
            prose-code:border prose-code:border-slate-800 prose-code:border-x-[0.5em] prose-code:border-solid
            prose-code:bg-slate-800 prose-code:text-red-400 prose-code:font-normal
            prose-code:before:content-[''] prose-code:after:content-['']

            --overridden
            prose-pre:bg-transparent prose-pre:block prose-pre:mb-4 prose-pre:p-0 prose-pre:mt-4
            prose-pre:before:content-['```'attr(data-lang)] prose-pre:after:content-['```']
            prose-pre:before:text-base prose-pre:after:text-base

            --links
            prose-a:text-green-400 hover:prose-a:underline prose-a:-mr-2
            prose-a:no-underline prose-a:font-semibold prose-a:inline
            prose-a:after:font-normal prose-a:after:underline prose-a:after:content-[attr(href)] prose-a:after:text-cyan-500

            --lists
            prose-ul:-ml-2

            --quotes
            prose-blockquote:border-l-[1px]
          ">
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

            <span class="inline-block bg-gray-300 px-2 text-gray-600">(END)</span>
          </article>
        </main>
      <% end %>
    </div>
    """
  end

  attr(:pink, :boolean, default: false)
  attr(:href, :string, default: nil)
  slot(:inner_block, required: true)
  attr(:rest, :global, include: ~w(disabled form name value))
  attr(:mobile?, :boolean, default: true)

  def button(assigns) do
    ~H"""
    <a
      class={"#{if @pink, do: "text-pink-300"} hover:bg-pink-300 hover:text-black px-2 cursor-pointer inline-block #{if not @mobile?, do: "hidden md:inline"}"}
      {@rest}
      href={@href}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
