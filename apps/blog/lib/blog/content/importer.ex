defmodule Blog.Content.Importer do
  @moduledoc """
  GenServer that watches the content directory and triggers imports when files change.

  Watches `priv/content/` directory and runs a full reimport of all content types
  (assets, then posts, then projects) whenever any file changes.

  Only starts filesystem watchers in development mode; in other environments, only
  performs the initial import on boot.

  In production with LiteFS, imports are only run on the primary node to avoid
  write conflicts on replicas.
  """

  use GenServer

  alias Blog.Assets.Asset
  alias Blog.Posts.Post
  alias Blog.Projects.Project

  require Logger

  @debounce_time_ms 500
  @litefs_poll_interval 1_000

  @type state :: %{
          watcher_pid: pid() | nil,
          timer_ref: reference() | nil,
          import_pending: boolean()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns the path to the content directory.
  """
  @spec content_path() :: Path.t()
  def content_path do
    case Blog.env() do
      :test ->
        Path.expand("../../test/fixtures/priv/content", __DIR__)

      _other ->
        :blog
        |> Application.app_dir()
        |> Path.join("priv/content")
    end
  end

  @doc """
  Runs a full import of all content types in the correct order.

  Imports assets first (since posts reference them for LQIP), then posts,
  then projects.
  """
  @spec import_all() :: :ok
  def import_all do
    Logger.info("Starting full content import...")

    with {:ok, assets} <- Asset.import(),
         {:ok, posts} <- Post.import(),
         {:ok, projects} <- Project.import() do
      Logger.info(
        "Content import complete: #{length(assets)} assets, #{length(posts)} posts, #{length(projects)} projects"
      )

      :ok
    else
      {:error, reason} ->
        Logger.error("Content import failed: #{inspect(reason)}")
        :ok
    end
  end

  @impl GenServer
  def init(_opts) do
    env = Blog.env()

    import_pending =
      if env == :test do
        false
      else
        send(self(), :check_litefs_ready)
        true
      end

    watcher_pid =
      if env == :dev do
        init_watcher()
      end

    {:ok, %{watcher_pid: watcher_pid, timer_ref: nil, import_pending: import_pending}}
  end

  @impl GenServer
  def handle_info(:check_litefs_ready, %{import_pending: false} = state) do
    {:noreply, state}
  end

  def handle_info(:check_litefs_ready, state) do
    cond do
      Blog.env() == :prod and not EctoLiteFS.tracker_ready?(Blog.Repo) ->
        Logger.debug("Waiting for LiteFS to be ready...")
        Process.send_after(self(), :check_litefs_ready, @litefs_poll_interval)
        {:noreply, state}

      Blog.env() == :prod and not EctoLiteFS.is_primary?(Blog.Repo) ->
        Logger.info("LiteFS ready but this node is a replica, skipping imports")
        {:noreply, %{state | import_pending: false}}

      true ->
        Logger.info("Running initial content import...")
        import_all()
        {:noreply, %{state | import_pending: false}}
    end
  end

  @impl GenServer
  def handle_info({:file_event, _watcher_pid, {path, events}}, state) do
    if valid_event?(events) do
      Logger.debug("File change detected: #{path}")
      {:noreply, schedule_import(state)}
    else
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info({:file_event, _watcher_pid, :stop}, state) do
    Logger.info("Filesystem watcher stopped")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:do_import, state) do
    import_all()
    {:noreply, %{state | timer_ref: nil}}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.debug("Unhandled message in Content.Importer: #{inspect(msg)}")
    {:noreply, state}
  end

  defp init_watcher do
    path = content_path()

    case FileSystem.start_link(dirs: [path], recursive: true) do
      {:ok, watcher_pid} ->
        FileSystem.subscribe(watcher_pid)
        Logger.info("Started content watcher on #{path}")
        watcher_pid

      {:error, reason} ->
        Logger.warning("Failed to start content watcher: #{inspect(reason)}")
        nil
    end
  end

  defp schedule_import(state) do
    state = cancel_existing_timer(state)

    timer_ref = Process.send_after(self(), :do_import, @debounce_time_ms)
    %{state | timer_ref: timer_ref}
  end

  defp cancel_existing_timer(%{timer_ref: nil} = state), do: state

  defp cancel_existing_timer(%{timer_ref: timer_ref} = state) do
    case Process.cancel_timer(timer_ref) do
      false ->
        receive do
          :do_import -> :ok
        after
          0 -> :ok
        end

      _time_left ->
        :ok
    end

    %{state | timer_ref: nil}
  end

  defp valid_event?(events) do
    Enum.any?(events, &(&1 in [:created, :modified, :removed, :renamed]))
  end
end
