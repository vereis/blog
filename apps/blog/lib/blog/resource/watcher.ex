defmodule Blog.Resource.Watcher do
  @moduledoc """
  GenServer that watches filesystem changes in resource directories and automatically
  triggers imports when files change.

  Monitors directories for each Blog.Resource implementation and runs initial imports on boot.
  """

  use GenServer

  require Logger

  # TODO: as we add more resources, we can dynamically discover them
  @resource_modules [
    Blog.Resource.Post,
    Blog.Resource.Image
  ]

  @debounce_time 100

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    env = Blog.env()

    for module <- @resource_modules, env == :dev do
      send(self(), {:do_import, module})
    end

    if env == :dev do
      watchers =
        @resource_modules
        |> Enum.map(&init_watcher/1)
        |> Enum.reject(&is_nil/1)
        |> Map.new(fn {module, pid, _source_dir} -> {pid, module} end)

      {:ok, %{watchers: watchers}}
    else
      {:ok, %{watchers: []}}
    end
  end

  @impl GenServer
  def handle_info({:file_event, watcher_pid, {_path, events}}, state) do
    valid_event? = valid_event?(events)

    case Map.get(state.watchers, watcher_pid) do
      module when valid_event? ->
        Logger.info("File change detected for #{module}")
        Process.send_after(self(), {:run_import, module}, @debounce_time)
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
  def handle_info({:run_import, module}, state) do
    Process.cancel_timer(Process.get({:import_timer, module}) || make_ref())

    # Schedule the actual import
    timer_ref = Process.send_after(self(), {:do_import, module}, @debounce_time)
    Process.put({:import_timer, module}, timer_ref)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:do_import, module}, state) do
    Process.delete({:import_timer, module})

    Logger.info("Running import for #{module}")

    case Blog.Resource.import(module) do
      :ok ->
        Logger.info("Successfully imported resources for #{module}")

      {:error, reason} ->
        Logger.error("Failed to import resources for #{module}: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.debug("Unhandled message in Resource.Watcher: #{inspect(msg)}")
    {:noreply, state}
  end

  defp init_watcher(module) do
    source_dir = module.source()

    case FileSystem.start_link(dirs: [source_dir]) do
      {:ok, watcher_pid} ->
        FileSystem.subscribe(watcher_pid)
        Logger.info("Started filesystem watcher for #{module} on #{source_dir}")
        {module, watcher_pid, source_dir}

      otherwise ->
        Logger.warning("Failed to start filesystem watcher for #{module}: #{inspect(otherwise)}")
        nil
    end
  end

  defp valid_event?(events), do: Enum.any?(events, &(&1 in [:created, :modified, :removed, :renamed]))
end
