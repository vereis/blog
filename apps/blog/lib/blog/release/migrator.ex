defmodule Blog.Release.Migrator do
  @moduledoc """
  GenServer that runs SQLite migrations on application startup.
  """
  use GenServer

  alias Blog.Release
  alias Blog.Repo.SQLite

  require Logger

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    :ok = Release.migrate(SQLite)
    {:ok, %{}}
  end
end
