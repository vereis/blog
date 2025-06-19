defmodule Blog.Lanyard do
  @moduledoc """
  Lanyard Discord presence integration context.
  """

  alias Blog.Lanyard.Connection
  alias Blog.Lanyard.Presence

  # Delegate presence functions to the Presence module
  defdelegate get_presence(), to: Presence
  defdelegate has_presence?(), to: Presence
  defdelegate refresh_presence(), to: Connection

  @doc """
  Get the configured Discord user ID.
  """
  @spec get_user_id() :: String.t()
  def get_user_id do
    Application.fetch_env!(:blog, :lanyard_discord_user_id)
  end

  @doc """
  Get the configured poll interval in milliseconds.
  """
  @spec poll_interval() :: pos_integer()
  def poll_interval do
    Application.fetch_env!(:blog, :lanyard_poll_interval)
  end

  @doc """
  Get the configured Lanyard API URL, optionally with a user ID appended.
  """
  @spec api_url(String.t() | nil) :: String.t()
  def api_url(user_id \\ nil) do
    base_url = Application.get_env(:blog, :lanyard_api_url, "https://api.lanyard.rest/v1/users")

    case user_id do
      nil -> base_url
      id -> "#{base_url}/#{id}"
    end
  end
end
