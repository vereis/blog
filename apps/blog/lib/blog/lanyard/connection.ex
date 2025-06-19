defmodule Blog.Lanyard.Connection do
  @moduledoc """
  HTTP polling client for Lanyard API.
  """
  use GenServer

  alias Blog.Lanyard
  alias Blog.Lanyard.Presence

  require Logger

  defmodule State do
    @moduledoc false
    defstruct [
      :poll_timer,
      status: :disconnected,
      last_presence: nil
    ]
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Force an immediate refresh of presence data.
  """
  @spec refresh_presence() :: {:ok, Presence.t()}
  def refresh_presence do
    :ok = GenServer.call(__MODULE__, :refresh_presence)
    {:ok, Presence.get_presence()}
  end

  @impl GenServer
  def init(_opts) do
    Logger.info("Starting Lanyard HTTP polling client")

    state = %State{}

    # Start polling immediately
    send(self(), :poll)

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:poll, state) do
    Logger.debug("Polling Lanyard API for Discord presence")

    case fetch_presence() do
      {:ok, presence_data} ->
        Logger.debug("Successfully fetched presence data")

        # Check if presence changed
        if presence_data != state.last_presence do
          Logger.info("Presence data changed, updating state")
          update_state(presence_data)
        end

        # Schedule next poll
        poll_interval = Lanyard.poll_interval()
        timer = Process.send_after(self(), :poll, poll_interval)

        {:noreply, %{state | status: :connected, last_presence: presence_data, poll_timer: timer}}

      {:error, reason} ->
        Logger.error("Failed to fetch presence data: #{inspect(reason)}")

        # Retry sooner on error
        timer = Process.send_after(self(), :poll, 5000)

        {:noreply, %{state | status: :error, poll_timer: timer}}
    end
  end

  def handle_info(message, state) do
    Logger.debug("Unhandled message: #{inspect(message)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:refresh_presence, _from, state) do
    Logger.info("Manual presence refresh requested")

    case fetch_presence() do
      {:ok, presence_data} ->
        update_state(presence_data)
        {:reply, :ok, %{state | last_presence: presence_data}}

      {:error, reason} ->
        Logger.error("Failed to refresh presence data: #{inspect(reason)}")
        {:reply, :ok, state}
    end
  end

  # Private functions

  defp fetch_presence do
    user_id = Lanyard.get_user_id()
    url = Lanyard.api_url(user_id)
    Logger.debug("Fetching presence from: #{url}")

    case Req.get(url) do
      {:ok, %{status: 200, body: %{"success" => true, "data" => data}}} ->
        Logger.debug("Successfully fetched presence data: #{inspect(data, pretty: true, limit: 5)}")

        {:ok, data}

      {:ok, %{status: 200, body: %{"success" => false, "error" => error}}} ->
        Logger.error("Lanyard API error: #{error}")
        {:error, {:api_error, error}}

      {:ok, %{status: status, body: body}} ->
        Logger.error("HTTP error: status #{status}, body: #{inspect(body)}")
        {:error, {:http_error, status}}

      {:error, reason} ->
        Logger.error("Request failed: #{inspect(reason)}")
        {:error, {:request_failed, reason}}
    end
  end

  defp update_state(presence_data) do
    {:ok, _presence} = Presence.update_presence(presence_data)
  end
end
