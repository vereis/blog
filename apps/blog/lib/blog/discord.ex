defmodule Blog.Discord do
  @moduledoc """
  Context module for Discord presence integration via Lanyard.

  This module provides a facade for reading Discord presence data
  from the ETS table managed by `Blog.Discord.Presence`.
  """

  alias Blog.Discord.Presence

  @ets_table_name :discord_presence
  @presence_key :current

  @doc """
  Gets the current Discord presence from ETS.

  Returns a disconnected presence if the table doesn't exist or is empty.
  """
  @spec get_presence() :: Presence.t()
  def get_presence do
    case :ets.lookup(@ets_table_name, @presence_key) do
      [{@presence_key, presence}] -> presence
      [] -> Presence.disconnected()
    end
  rescue
    ArgumentError ->
      # ETS table doesn't exist (e.g., in tests or before WebSocket connects)
      Presence.disconnected()
  end

  @doc """
  Checks if we have an active Discord presence connection.
  """
  @spec connected?() :: boolean()
  def connected? do
    get_presence().connected?
  end

  @doc """
  Gets the configured Discord user ID.
  """
  @spec get_user_id() :: String.t()
  def get_user_id do
    Application.fetch_env!(:blog, :discord_user_id)
  end
end
