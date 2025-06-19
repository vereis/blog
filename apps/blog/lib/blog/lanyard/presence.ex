defmodule Blog.Lanyard.Presence do
  @moduledoc """
  GenServer responsible for managing Discord presence state in an ETS table.

  This GenServer owns the ETS table and is the single source of truth for
  presence data mutations. The table has read concurrency enabled for
  efficient direct reads by other processes.
  """
  use GenServer

  require Logger

  @presence_key :current_presence

  @type t :: %__MODULE__{
          discord_user: map() | nil,
          activities: list(),
          discord_status: String.t(),
          active_on_discord_web: boolean(),
          active_on_discord_desktop: boolean(),
          active_on_discord_mobile: boolean(),
          listening_to_spotify: boolean(),
          spotify: map() | nil,
          connected?: boolean()
        }

  defstruct discord_user: nil,
            activities: [],
            discord_status: "offline",
            active_on_discord_web: false,
            active_on_discord_desktop: false,
            active_on_discord_mobile: false,
            listening_to_spotify: false,
            spotify: nil,
            connected?: false

  @doc """
  Create a new presence struct from raw API data.
  """
  @spec from_api_data(map()) :: t()
  def from_api_data(api_data) do
    %__MODULE__{
      discord_user: api_data["discord_user"],
      activities: api_data["activities"] || [],
      discord_status: api_data["discord_status"],
      active_on_discord_web: api_data["active_on_discord_web"] || false,
      active_on_discord_desktop: api_data["active_on_discord_desktop"] || false,
      active_on_discord_mobile: api_data["active_on_discord_mobile"] || false,
      listening_to_spotify: api_data["listening_to_spotify"] || false,
      spotify: api_data["spotify"],
      connected?: true
    }
  end

  @doc """
  Return a default disconnected presence.
  """
  @spec disconnected() :: t()
  def disconnected do
    %__MODULE__{connected?: false}
  end

  # Client API

  @doc """
  Start the presence GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Update the current presence data (synchronous).
  """
  @spec update_presence(map()) :: {:ok, t()}
  def update_presence(presence_data) do
    GenServer.call(__MODULE__, {:update_presence, presence_data})
  end

  @doc """
  Get the current presence data directly from ETS.
  This is a fast read operation that doesn't require messaging the GenServer.
  Returns a disconnected presence if no data exists.
  """
  @spec get_presence() :: t()
  def get_presence do
    case :ets.lookup(__MODULE__, @presence_key) do
      [{@presence_key, presence_data}] -> presence_data
      [] -> disconnected()
    end
  rescue
    ArgumentError ->
      # ETS table doesn't exist (e.g., in tests)
      disconnected()
  end

  @doc """
  Check if presence data indicates a connected state.
  """
  @spec has_presence?() :: boolean()
  def has_presence? do
    get_presence().connected?
  end

  # GenServer callbacks

  @impl GenServer
  def init(_opts) do
    Logger.info("Starting Lanyard presence manager")

    # Create ETS table with read concurrency enabled
    :ets.new(__MODULE__, [
      :set,
      :named_table,
      :public,
      read_concurrency: true
    ])

    Logger.debug("Created ETS table #{__MODULE__} for presence state")

    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:update_presence, presence_data}, _from, state) do
    Logger.debug("Updating presence state: #{inspect(presence_data, pretty: true, limit: 3)}")

    # Convert raw API data to struct
    presence_struct = from_api_data(presence_data)

    # Insert/update the presence data in ETS
    :ets.insert(__MODULE__, {@presence_key, presence_struct})

    Logger.info("Presence state updated successfully")

    {:reply, {:ok, presence_struct}, state}
  end

  @impl GenServer
  def handle_call(msg, _from, state) do
    Logger.warning("Unhandled call message: #{inspect(msg)}")
    {:reply, {:error, :unknown_call}, state}
  end

  @impl GenServer
  def handle_cast(msg, state) do
    Logger.warning("Unhandled cast message: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.warning("Unhandled info message: #{inspect(msg)}")
    {:noreply, state}
  end
end
