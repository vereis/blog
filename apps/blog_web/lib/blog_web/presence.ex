defmodule BlogWeb.Presence do
  @moduledoc """
  Tracks blog viewers in real-time.
  """
  use Phoenix.Presence,
    otp_app: :blog_web,
    pubsub_server: Blog.PubSub

  defmodule NavigationResult do
    @moduledoc "Result of page navigation with updated viewer counts"
    defstruct [:page_topic, :site_viewers, :page_viewers]

    @type t :: %__MODULE__{
            page_topic: String.t(),
            site_viewers: non_neg_integer(),
            page_viewers: non_neg_integer()
          }
  end

  @site_topic "blog:viewers:site"

  @doc """
  Initialize presence tracking for a viewer.
  Sets up PubSub subscriptions and tracks the viewer.
  Returns {:ok, NavigationResult} or {:error, reason}.
  """
  @spec init_viewer(pid(), String.t(), atom(), map()) ::
          {:ok, NavigationResult.t()} | {:error, term()}
  def init_viewer(pid, user_id, live_action, params) do
    page_topic = get_page_topic(live_action, params)

    with :ok <- Phoenix.PubSub.subscribe(Blog.PubSub, @site_topic),
         :ok <- Phoenix.PubSub.subscribe(Blog.PubSub, page_topic_key(page_topic)),
         :ok <- track_viewer(pid, user_id, page_topic) do
      {site_count, page_count} = get_viewer_counts(page_topic)

      result = %NavigationResult{
        page_topic: page_topic,
        site_viewers: site_count,
        page_viewers: page_count
      }

      {:ok, result}
    end
  end

  @doc """
  Refresh viewer counts from presence diff.
  Returns {site_count, page_count} or nil if no current page.
  """
  @spec refresh_counts(String.t() | nil) :: {non_neg_integer(), non_neg_integer()} | nil
  def refresh_counts(current_page_topic) do
    if current_page_topic do
      get_viewer_counts(current_page_topic)
    end
  end

  @doc """
  Track a viewer on both site-wide and page-specific topics.
  Returns :ok on success or {:error, reason} on failure.
  """
  @spec track_viewer(pid(), String.t(), String.t()) :: :ok | {:error, term()}
  def track_viewer(pid, user_id, page_topic) do
    with {:ok, _ref1} <- track(pid, @site_topic, user_id, %{page: page_topic}),
         {:ok, _ref2} <- track(pid, page_topic_key(page_topic), user_id, %{}) do
      :ok
    end
  end

  @doc """
  Update viewer tracking when they navigate to a new page.
  """
  @spec update_viewer(pid(), String.t(), String.t() | nil, String.t()) :: :ok
  def update_viewer(_pid, _user_id, same_topic, same_topic), do: :ok

  def update_viewer(pid, user_id, old_page_topic, new_page_topic) do
    # Untrack from old page if it exists
    if old_page_topic do
      untrack(pid, page_topic_key(old_page_topic), user_id)
    end

    # Track on new page and update site-wide metadata
    track(pid, page_topic_key(new_page_topic), user_id, %{})
    update(pid, @site_topic, user_id, %{page: new_page_topic})
  end

  @doc """
  Get current viewer counts for site and specific page.
  Returns {site_count, page_count}.
  """
  @spec get_viewer_counts(String.t()) :: {non_neg_integer(), non_neg_integer()}
  def get_viewer_counts(page_topic) do
    site_count = @site_topic |> list() |> map_size()
    page_count = page_topic |> page_topic_key() |> list() |> map_size()
    {site_count, page_count}
  end

  @doc """
  Generate page topic key from live action and params.
  """
  @spec get_page_topic(atom(), map()) :: String.t()
  def get_page_topic(live_action, params) do
    case live_action do
      :home -> "home"
      :show_post -> "post:#{params["slug"] || "unknown"}"
      :list_posts -> "posts"
      :list_projects -> "projects"
      _otherwise -> "home"
    end
  end

  @doc """
  Handle page navigation by updating presence tracking.
  Returns {:ok, NavigationResult} with updated counts.
  LiveView should check if page_topic changed before updating assigns.
  """
  @spec handle_page_navigation(pid(), String.t(), atom(), map(), String.t() | nil) ::
          {:ok, NavigationResult.t()}
  def handle_page_navigation(pid, user_id, live_action, params, old_page_topic) do
    new_page_topic = get_page_topic(live_action, params)

    update_viewer(pid, user_id, old_page_topic, new_page_topic)
    {site_count, page_count} = get_viewer_counts(new_page_topic)

    result = %NavigationResult{
      page_topic: new_page_topic,
      site_viewers: site_count,
      page_viewers: page_count
    }

    {:ok, result}
  end

  @spec page_topic_key(String.t()) :: String.t()
  defp page_topic_key(page_topic), do: "blog:viewers:#{page_topic}"
end
