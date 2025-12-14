defmodule BlogWeb.Viewers do
  @moduledoc """
  Context module for tracking and querying viewer presence across the site.

  This module provides a clean API for LiveViews to interact with
  Phoenix.Presence without coupling to the implementation details.

  ## Topics

  - `"viewers:site"` - All active users across the entire site
  - `"viewers:page:home"` - Home page viewers
  - `"viewers:page:posts"` - Posts list viewers
  - `"viewers:page:post:<slug>"` - Individual post viewers
  - `"viewers:page:projects"` - Projects list viewers
  - `"viewers:page:gallery"` - Gallery viewers
  """

  @site_topic "viewers:site"

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
  Gets the current viewer count for a specific topic.

  ## Examples

      Viewers.get_viewer_count("viewers:site")
      #=> 5

      Viewers.get_viewer_count("viewers:page:home")
      #=> 2
  """
  @spec get_viewer_count(String.t()) :: non_neg_integer()
  def get_viewer_count(topic) do
    topic
    |> BlogWeb.Presence.list()
    |> map_size()
  end

  @doc """
  Gets viewer counts for all common topics.

  Returns a map with topic names as keys and counts as values.

  ## Examples

      Viewers.get_all_counts()
      #=> %{
      #=>   site: 10,
      #=>   home: 3,
      #=>   posts: 2,
      #=>   projects: 1,
      #=>   gallery: 0
      #=> }
  """
  @spec get_all_counts() :: %{atom() => non_neg_integer()}
  def get_all_counts do
    %{
      site: get_viewer_count(@site_topic),
      home: get_viewer_count("viewers:page:home"),
      posts: get_viewer_count("viewers:page:posts"),
      projects: get_viewer_count("viewers:page:projects"),
      gallery: get_viewer_count("viewers:page:gallery")
    }
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

  @doc """
  Returns the site-wide topic name.

  ## Examples

      Viewers.site_topic()
      #=> "viewers:site"
  """
  @spec site_topic() :: String.t()
  def site_topic, do: @site_topic

  @doc """
  Returns the topic name for a specific page.

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
  def page_topic(:home), do: "viewers:page:home"
  def page_topic(:posts), do: "viewers:page:posts"
  def page_topic(:projects), do: "viewers:page:projects"
  def page_topic(:gallery), do: "viewers:page:gallery"

  @doc """
  Returns the topic name for a specific post by slug.

  ## Examples

      Viewers.post_topic("hello-world")
      #=> "viewers:page:post:hello-world"
  """
  @spec post_topic(String.t()) :: String.t()
  def post_topic(slug), do: "viewers:page:post:#{slug}"
end
