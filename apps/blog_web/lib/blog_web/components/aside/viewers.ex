defmodule BlogWeb.Components.Aside.Viewers do
  @moduledoc """
  Viewer tracking and display functionality.

  This module combines viewer presence tracking with UI components
  for displaying real-time viewer statistics.

  ## Topics

  - `"viewers:site"` - All active users across the entire site
  - `"viewers:page:home"` - Home page viewers
  - `"viewers:page:posts"` - Posts list viewers
  - `"viewers:page:post:<slug>"` - Individual post viewers
  - `"viewers:page:projects"` - Projects list viewers
  - `"viewers:page:gallery"` - Gallery viewers
  """
  use Phoenix.Component

  alias BlogWeb.Components.Aside

  @site_topic "viewers:site"

  # ============================================================================
  # Component Functions
  # ============================================================================

  @doc """
  Renders viewer count information in the aside.

  ## Examples

      <Viewers.counts site_count={@site_viewer_count} page_count={@page_viewer_count} />
  """
  attr :site_count, :integer, required: true
  attr :page_count, :integer, required: true
  attr :id, :string, default: "viewer-counts"
  attr :open, :boolean, default: true

  def counts(assigns) do
    ~H"""
    <Aside.aside_section title="Viewers" id={@id} open={@open}>
      <div class="viewer-counts" aria-label="Viewer Counts">
        <p class="viewer-stat">
          <span class="viewer-bullet">•</span>
          <span class="viewer-label">Site-wide:</span>
          <span class="viewer-count">{@site_count}</span>
        </p>

        <p class="viewer-stat">
          <span class="viewer-bullet">•</span>
          <span class="viewer-label">This page:</span>
          <span class="viewer-count">{@page_count}</span>
        </p>
      </div>
    </Aside.aside_section>
    """
  end

  # ============================================================================
  # Tracking Functions
  # ============================================================================

  @doc """
  Tracks a viewer on a specific topic.

  ## Parameters

  - `pid` - The process to track (usually `self()` from a LiveView)
  - `topic` - The presence topic to track on
  - `key` - Unique identifier for this viewer (usually `socket.id`)
  - `meta` - Optional metadata map (default: `%{}`)

  ## Examples

      # Track on site-wide topic
      Viewers.track_viewer(self(), "viewers:site", socket.id)

      # Track on a specific page
      Viewers.track_viewer(self(), "viewers:page:home", socket.id)

      # Track with metadata
      Viewers.track_viewer(self(), "viewers:site", socket.id, %{joined_at: System.system_time()})
  """
  @spec track_viewer(pid(), String.t(), String.t(), map()) :: {:ok, binary()} | {:error, term()}
  def track_viewer(pid, topic, key, meta \\ %{}) do
    BlogWeb.Presence.track(pid, topic, key, meta)
  end

  @doc """
  Untracks a viewer from a specific topic.

  ## Parameters

  - `pid` - The process to untrack
  - `topic` - The presence topic to untrack from
  - `key` - The unique identifier for this viewer

  ## Examples

      Viewers.untrack_viewer(self(), "viewers:page:posts", socket.id)
  """
  @spec untrack_viewer(pid(), String.t(), String.t()) :: :ok
  def untrack_viewer(pid, topic, key) do
    BlogWeb.Presence.untrack(pid, topic, key)
  end

  @doc """
  Gets the current viewer count.

  ## Patterns

  - `count()` - Returns site-wide viewer count
  - `count(:page)` - Returns viewer count for a specific page (`:home`, `:posts`, `:projects`, `:gallery`)
  - `count(posts: [])` - Returns viewer count for posts list (works for any page type)
  - `count(posts: "slug")` - Returns viewer count for a specific post (works for any resource type)

  Note: Keyword list syntax only accepts single-element lists.

  ## Examples

      # Site-wide count
      Viewers.count()
      #=> 10

      # Page counts (atom shorthand)
      Viewers.count(:home)
      #=> 2

      Viewers.count(:posts)
      #=> 3

      # Page counts (keyword list - works for any page type)
      Viewers.count(posts: [])
      #=> 3

      Viewers.count(projects: [])
      #=> 2

      # Individual resource by identifier (works for any resource type)
      Viewers.count(posts: "hello-world")
      #=> 1

      Viewers.count(projects: "my-project")
      #=> 1
  """
  @spec count() :: non_neg_integer()
  def count do
    @site_topic
    |> BlogWeb.Presence.list()
    |> map_size()
  end

  @spec count(atom() | keyword()) :: non_neg_integer()
  def count(page) when is_atom(page) do
    ["page", page]
    |> build_topic()
    |> BlogWeb.Presence.list()
    |> map_size()
  end

  def count(opts) when is_list(opts) and length(opts) == 1 do
    opts
    |> build_topic_from_opts()
    |> BlogWeb.Presence.list()
    |> map_size()
  end

  def count(opts) when is_list(opts) do
    raise ArgumentError,
          "count/1 only accepts single-element keyword lists, got: #{inspect(opts)}"
  end

  # ============================================================================
  # Topic Building
  # ============================================================================

  defp build_topic(parts) do
    Enum.map_join(["viewers" | parts], ":", &to_string/1)
  end

  defp build_topic_from_opts([{page, []}]) when is_atom(page) do
    build_topic(["page", page])
  end

  defp build_topic_from_opts([{page, identifier}]) when is_atom(page) and is_binary(identifier) do
    build_topic(["page", page, identifier])
  end

  defp build_topic_from_opts(invalid) do
    raise ArgumentError, """
    Invalid count/1 keyword list format: #{inspect(invalid)}

    Expected one of:
      - [{:page_atom, []}] for page lists (e.g., posts: [])
      - [{:page_atom, "identifier"}] for specific resources (e.g., posts: "slug")
    """
  end

  @doc """
  Subscribes the current process to presence updates for a topic.

  This allows a process to receive `:viewer_count_updated`, `:viewer_joined`,
  and `:viewer_left` messages.

  ## Examples

      Viewers.subscribe("viewers:site")
      #=> :ok

      # Later, in handle_info:
      def handle_info({:viewer_count_updated, topic, count}, socket) do
        {:noreply, assign(socket, :viewer_count, count)}
      end
  """
  @spec subscribe(String.t()) :: :ok | {:error, term()}
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Blog.PubSub, topic)
  end

  # ============================================================================
  # Topic Helpers (Public API for tracking/subscribing)
  # ============================================================================

  @doc """
  Returns the site-wide topic name.

  Used for tracking and subscribing to site-wide viewer updates.

  ## Examples

      Viewers.site_topic()
      #=> "viewers:site"
  """
  @spec site_topic() :: String.t()
  def site_topic, do: @site_topic

  @doc """
  Returns the topic name for a specific page.

  Used for tracking and subscribing to page-specific viewer updates.

  ## Parameters

  - `page` - Page identifier (`:home`, `:posts`, `:projects`, `:gallery`)

  ## Examples

      Viewers.page_topic(:home)
      #=> "viewers:page:home"

      Viewers.page_topic(:posts)
      #=> "viewers:page:posts"
  """
  @type page :: :home | :posts | :projects | :gallery
  @spec page_topic(page()) :: String.t()
  def page_topic(page) when is_atom(page) do
    build_topic(["page", page])
  end

  @doc """
  Returns the topic name for a specific resource by page type and identifier.

  Used for tracking and subscribing to individual resource viewer updates.

  ## Examples

      Viewers.resource_topic(:posts, "hello-world")
      #=> "viewers:page:posts:hello-world"

      Viewers.resource_topic(:projects, "my-project")
      #=> "viewers:page:projects:my-project"
  """
  @spec resource_topic(atom(), String.t()) :: String.t()
  def resource_topic(page, identifier) when is_atom(page) and is_binary(identifier) do
    build_topic(["page", page, identifier])
  end

  @doc """
  Returns the topic name for a specific post by slug.

  Convenience function for `resource_topic(:posts, slug)`.

  ## Examples

      Viewers.post_topic("hello-world")
      #=> "viewers:page:posts:hello-world"
  """
  @spec post_topic(String.t()) :: String.t()
  def post_topic(slug) when is_binary(slug) do
    resource_topic(:posts, slug)
  end
end
