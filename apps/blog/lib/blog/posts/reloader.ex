defmodule Blog.Posts.Reloader do
  @moduledoc false
  use GenServer

  alias Blog.Migrator
  alias Blog.Posts.Importer

  require Logger

  @state %{}
  @timeout 150

  @spec start_link(args :: any()) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(_args) do
    :ok = maybe_init_filesystem_watcher()
    {:ok, @state, 0}
  end

  @spec maybe_init_filesystem_watcher() :: :ok
  if Code.ensure_loaded?(FileSystem) do
    defp maybe_init_filesystem_watcher do
      {:ok, watcher_pid} = FileSystem.start_link(dirs: [Posts.source_path()])
      FileSystem.subscribe(watcher_pid)
      :ok
    end
  else
    defp maybe_init_filesystem_watcher do
      :ok
    end
  end

  @impl GenServer
  def handle_info({:file_event, _watcher_pid, {_path, _events}}, state) do
    {:noreply, state, @timeout}
  end

  def handle_info({:file_event, _watcher_pid, :stop}, state) do
    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    Logger.info("Reloading posts...")
    Migrator.migrate()
    Importer.run!()
    {:noreply, state}
  end
end
