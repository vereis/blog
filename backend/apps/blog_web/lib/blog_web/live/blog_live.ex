defmodule BlogWeb.BlogLive do
  use Phoenix.LiveView
  use BlogWeb, :verified_routes

  alias Blog.Posts

  @projects [
    sibyl: "https://github.com/vetspire/sibyl",
    endo: "https://github.com/vetspire/endo",
    ecto_utils: "https://github.com/vereis/ecto_utils",
    ecto_middleware: "https://github.com/vereis/ecto_middleware"
  ]

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      socket
      |> assign_new(:posts, fn -> Posts.list_posts(order_by: [desc: :published_at]) end)
      |> assign_new(:post, fn -> Posts.get_post(slug: params["slug"] || "hello_world") end)
      |> assign_new(:projects, fn -> @projects end)
      |> assign_new(:tag, fn -> nil end)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, uri, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("home", _, socket) do
    socket = assign(socket, :post, Posts.get_post(1))
    {:noreply, push_patch(socket, to: ~p"/")}
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
  def render(assigns) do
    ~H"""
    <div class="text-white max-w-3xl mx-auto space-y-8 p-6 border-x-[1px] border-white/25">
      <header class="flex justify-between font-mono">
        <span>
          <.button pink="true" phx-click="home">vereis</.button>
          <.button phx-click="posts">posts</.button>
          <.button href="https://github.com/vereis/blog">&lt;/&gt;</.button>
        </span>
        <span>
          <%= for {label, link} <- @projects do %>
            <.button class="px-2" href={link}><%= label %></.button>
          <% end %>
        </span>
      </header>

      <%= if @live_action == :list_posts do %>
        <main class="px-4 mx-auto">
          <div>
            <h1 class="px-2 bg-blue-700 inline-block mb-4">
              All Posts <%= if @tag, do: "tagged #{@tag}", else: "" %>
            </h1>
            <%= if @tag do %>
              <a class="cursor-pointer underline italic" phx-click="posts">(clear)</a>
            <% end %>
          </div>
          <%= for post <- @posts, is_nil(@tag) or Enum.any?(post.tags, & &1.label == @tag) do %>
            <div phx-click="post" phx-value-post={post.slug} class="cursor-pointer grid grid-cols-12">
              <div class="before:content-['#'] before:-mr-2 text-green-400 col-start-1 col-end-2">
                <%= post.id %>
              </div>
              <div class="col-start-2 col-end-7 hover:underline"><%= post.title %></div>
              <div class="col-start-7 col-end-11 text-right">
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
              <div class="col-start-11 col-end-13 text-right">
                <%= DateTime.to_date(post.published_at) %>
              </div>
            </div>
          <% end %>
          <span class="inline-block bg-gray-300 my-4 px-2 text-gray-600">(END)</span>
        </main>
      <% end %>

      <%= if @live_action in [:show_post, :home] do %>
        <main class="px-4 mx-auto">
          <div class="flex justify-between items-center">
            <h1 class="px-2 bg-blue-700 inline-block"><%= @post.title %></h1>
            <div class="flex flex-row-reverse items-center -mr-2">
              <%= for tag <- @post.tags do %>
                <.button class="px-2" phx-click="tag" phx-value-tag={tag.label}>
                  <%= tag.label %>
                </.button>
              <% end %>
              Tagged:&nbsp
            </div>
          </div>
          <div class="flex flex-row-reverse mb-2 text-gray-400">
            Published <%= DateTime.to_date(@post.published_at) %> @ <%= DateTime.to_time(
              @post.published_at
            ) %>
          </div>
          <article class="
        prose prose-mono max-w-none leading-tight
        selection:bg-pink-300 selection:text-pink-900

        --headings
        prose-headings:text-base prose-headings:mb-4 prose-headings:mt-0 prose-headings:text-blue-500 prose-headings:inline-block
        prose-h1:text-base prose-h1:px-2 prose-h1:bg-blue-700 prose-h1:text-white prose-h1:-mb-2
        prose-h2:before:content-['##']
        prose-h3:before:content-['###']
        prose-h4:before:content-['####']
        prose-h5:before:content-['#####']
        prose-h6:before:content-['######']

        --code-blocks
        prose-code:text-base prose-code:inline-block
        prose-code:-mr-2 prose-code:px-2
        prose-code:bg-slate-800 prose-code:text-red-400 prose-code:font-normal
        prose-code:before:content-[''] prose-code:after:content-['']

        prose-pre:bg-transparent prose-pre:block prose-pre:ml-4 prose-pre:mb-4 prose-pre:p-0 prose-pre:mt-4

        --links
        prose-a:text-green-400 hover:prose-a:underline prose-a:-mr-2
        prose-a:no-underline prose-a:font-semibold prose-a:inline
        prose-a:after:font-normal prose-a:after:underline prose-a:after:content-[attr(href)] prose-a:after:text-cyan-500

        --lists
        prose-ul:-ml-2

        --quotes
        prose-blockquote:border-l-[1px]
      ">
            <%= {:safe, @post.body} %>
            <span class="inline-block bg-gray-300 px-2 text-gray-600">(END)</span>
          </article>
        </main>
      <% end %>
    </div>
    """
  end

  attr :pink, :boolean, default: false
  slot :inner_block, required: true
  attr :rest, :global, include: ~w(disabled form name value)

  def button(assigns) do
    ~H"""
    <a
      class={"#{if @pink, do: "text-pink-300"} hover:bg-pink-300 hover:text-black px-2 cursor-pointer inline-block"}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
