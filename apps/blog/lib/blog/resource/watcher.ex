defmodule Blog.Resource.Watcher do
  @moduledoc """
  GenServer that watches filesystem changes in resource directories and automatically
  triggers imports when files change.

  Monitors directories for each configured Blog.Resource implementation and runs initial
  imports on boot.

  Only starts filesystem watchers in development mode; in other environments, only performs
  the initial import.

  ## Configuration

  Pass schemas via start_link options:

      {Blog.Resource.Watcher, schemas: [Blog.Posts.Post, Blog.Assets.Asset]}

  """

  use GenServer

  require Logger

  @debounce_time_ms 250

  @type state :: %{
          schemas: [module()],
          watchers: %{pid() => module()},
          timers: %{module() => reference()}
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(opts) do
    schemas = Keyword.get(opts, :schemas, [])
    env = Blog.env()

    for schema <- schemas, env != :test do
      send(self(), {:do_import, schema})
    end

    watchers =
      if env == :dev do
        schemas
        |> Enum.map(&init_watcher/1)
        |> Enum.reject(&is_nil/1)
        |> Map.new(fn {schema, pid, _source_dir} -> {pid, schema} end)
      else
        %{}
      end

    {:ok, %{schemas: schemas, watchers: watchers, timers: %{}}}
  end

  @impl GenServer
  def handle_info({:file_event, watcher_pid, {_path, events}}, state) do
    valid_event? = valid_event?(events)

    case Map.get(state.watchers, watcher_pid) do
      schema when not is_nil(schema) and valid_event? ->
        Logger.debug("File change detected for #{inspect(schema)}")
        send(self(), {:schedule_import, schema})
        {:noreply, state}

      _otherwise ->
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info({:file_event, watcher_pid, :stop}, state) do
    Logger.info("Filesystem watcher stopped: #{inspect(watcher_pid)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:schedule_import, schema}, state) do
    state =
      case Map.get(state.timers, schema) do
        nil ->
          state

        timer_ref ->
          case Process.cancel_timer(timer_ref) do
            false ->
              receive do
                {:do_import, ^schema} -> :ok
              after
                0 -> :ok
              end

              state

            _time_left ->
              state
          end
      end

    new_timer_ref = Process.send_after(self(), {:do_import, schema}, @debounce_time_ms)
    {:noreply, %{state | timers: Map.put(state.timers, schema, new_timer_ref)}}
  end

  @impl GenServer
  def handle_info({:do_import, schema}, state) do
    Logger.info("Running import for #{inspect(schema)}")

    case schema.import() do
      {:ok, _resources} ->
        Logger.info("Successfully imported resources for #{inspect(schema)}")

      {:error, reason} ->
        Logger.error("Failed to import resources for #{inspect(schema)}: #{inspect(reason)}")
    end

    {:noreply, %{state | timers: Map.delete(state.timers, schema)}}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.debug("Unhandled message in Resource.Watcher: #{inspect(msg)}")
    {:noreply, state}
  end

  defp init_watcher(schema) do
    source_dir = schema.source()

    case FileSystem.start_link(dirs: [source_dir]) do
      {:ok, watcher_pid} ->
        FileSystem.subscribe(watcher_pid)
        Logger.info("Started watcher for #{inspect(schema)} on #{source_dir}")
        {schema, watcher_pid, source_dir}

      otherwise ->
        Logger.warning("Failed to start watcher for #{inspect(schema)}: #{inspect(otherwise)}")
        nil
    end
  end

  defp valid_event?(events) do
    Enum.any?(events, &(&1 in [:created, :modified, :removed, :renamed]))
  end
end
