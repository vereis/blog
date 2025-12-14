defmodule Blog.Discord.Presence do
  @moduledoc """
  WebSocket client for Lanyard Discord presence integration.

  This module handles:
  - WebSocket connection to Lanyard API
  - Heartbeat to keep connection alive
  - Automatic reconnection on disconnect
  - ETS table management for concurrent reads
  - PubSub broadcasts on presence updates
  """
  use WebSockex

  require Logger

  @websocket_url "wss://api.lanyard.rest/socket"
  @ets_table_name :discord_presence
  @presence_key :current

  defmodule State do
    @moduledoc false
    defstruct [:heartbeat_timer, :heartbeat_interval]
  end

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
  Starts the WebSocket client.
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts \\ []) do
    state = %State{
      heartbeat_timer: nil,
      heartbeat_interval: nil
    }

    WebSockex.start_link(@websocket_url, __MODULE__, state, [name: __MODULE__] ++ opts)
  end

  @doc """
  Creates a presence struct from API data.
  """
  @spec from_api_data(map()) :: t()
  def from_api_data(api_data) do
    %__MODULE__{
      discord_user: api_data["discord_user"],
      activities: api_data["activities"] || [],
      discord_status: api_data["discord_status"] || "offline",
      active_on_discord_web: api_data["active_on_discord_web"] || false,
      active_on_discord_desktop: api_data["active_on_discord_desktop"] || false,
      active_on_discord_mobile: api_data["active_on_discord_mobile"] || false,
      listening_to_spotify: api_data["listening_to_spotify"] || false,
      spotify: api_data["spotify"],
      connected?: true
    }
  end

  @doc """
  Returns a disconnected presence.
  """
  @spec disconnected() :: t()
  def disconnected do
    %__MODULE__{connected?: false}
  end

  # WebSockex Callbacks

  @impl WebSockex
  def handle_connect(_conn, state) do
    Logger.info("[Discord.Presence] Connected to Lanyard WebSocket")

    # NOTE: Clients need to be able to query Discord presence data, and we have
    #       (at least) one client per person viewing the site at any time.
    #
    #       Let's handle presence lookups via an ETS table so that we don't end
    #       up serializing (and potentially building up a lot of) requests.
    case :ets.whereis(@ets_table_name) do
      :undefined ->
        :ets.new(@ets_table_name, [
          :set,
          :named_table,
          :public,
          read_concurrency: true
        ])

        Logger.debug("[Discord.Presence] Created ETS table")

      _tid ->
        Logger.debug("[Discord.Presence] ETS table already exists, skipping creation")
    end

    {:ok, state}
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      # Opcode 1: Start heartbeat and send Initialize
      {:ok, %{"op" => 1, "d" => %{"heartbeat_interval" => interval}}} ->
        Logger.info("[Discord.Presence] Received Hello, heartbeat interval: #{interval}ms")

        if state.heartbeat_timer, do: Process.cancel_timer(state.heartbeat_timer)
        timer = Process.send_after(self(), :heartbeat, interval)

        # Send Initialize message
        user_id = Application.fetch_env!(:blog, :discord_user_id)
        init_payload = %{op: 2, d: %{subscribe_to_id: user_id}}

        Logger.debug("[Discord.Presence] Sending Initialize for user: #{user_id}")
        {:reply, {:text, Jason.encode!(init_payload)}, %{state | heartbeat_timer: timer, heartbeat_interval: interval}}

      # Opcode 0: Event: INIT_STATE
      {:ok, %{"op" => 0, "t" => "INIT_STATE", "d" => data}} ->
        Logger.info("[Discord.Presence] Received INIT_STATE")
        presence = from_api_data(data)
        update_ets_and_broadcast(presence)
        {:ok, state}

      # Opcode 0: Event: PRESENCE_UPDATE
      {:ok, %{"op" => 0, "t" => "PRESENCE_UPDATE", "d" => data}} ->
        Logger.info("[Discord.Presence] Received PRESENCE_UPDATE")
        presence = from_api_data(data)
        update_ets_and_broadcast(presence)
        {:ok, state}

      {:ok, other} ->
        Logger.debug("[Discord.Presence] Unknown message: #{inspect(other)}")
        {:ok, state}

      {:error, reason} ->
        Logger.error("[Discord.Presence] Failed to decode message: #{inspect(reason)}")
        {:ok, state}
    end
  end

  @impl WebSockex
  def handle_info(:heartbeat, state) do
    Logger.debug("[Discord.Presence] Sending heartbeat")
    timer = Process.send_after(self(), :heartbeat, state.heartbeat_interval)
    {:reply, {:text, Jason.encode!(%{op: 3})}, %{state | heartbeat_timer: timer}}
  end

  @impl WebSockex
  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("[Discord.Presence] Disconnected: #{inspect(reason)}")
    if state.heartbeat_timer, do: Process.cancel_timer(state.heartbeat_timer)
    {:reconnect, %{state | heartbeat_timer: nil}}
  end

  defp update_ets_and_broadcast(presence) do
    :ets.insert(@ets_table_name, {@presence_key, presence})
    Logger.debug("[Discord.Presence] Updated ETS table with new presence")
    Phoenix.PubSub.broadcast(Blog.PubSub, "discord:presence", {:presence_updated, presence})
    Logger.debug("[Discord.Presence] Broadcasted presence update")
  end
end
