defmodule BlogWeb.Components.Aside.Discord do
  @moduledoc """
  Discord presence component for displaying real-time user status.
  """
  use Phoenix.Component

  alias BlogWeb.Components.Aside

  @doc """
  Renders Discord presence information in the aside.

  ## Examples

      <Discord.presence presence={@presence} />
  """
  attr :presence, :map, required: true
  attr :id, :string, default: "discord-presence"
  attr :open, :boolean, default: true

  def presence(assigns) do
    ~H"""
    <Aside.aside_section title="Presence" id={@id} open={@open}>
      <div class="discord-presence" aria-label="Discord Presence">
        <p class="discord-status">
          <span class={["discord-bullet", bullet_class(@presence)]}>•</span>
          <span class="discord-username">{username(@presence)}</span>
          <span class="discord-status-text">{status(@presence)}</span>
        </p>

        <p :if={@presence.connected? && activity(@presence)} class="discord-activity">
          {activity(@presence)}
        </p>

        <p :if={@presence.listening_to_spotify && @presence.spotify} class="discord-spotify">
          {@presence.spotify["song"]} — {@presence.spotify["artist"]}
        </p>
      </div>
    </Aside.aside_section>
    """
  end

  # Private helper functions

  defp bullet_class(%{connected?: false}), do: "bullet-offline"
  defp bullet_class(%{discord_status: "online"}), do: "bullet-online"
  defp bullet_class(%{discord_status: "idle"}), do: "bullet-idle"
  defp bullet_class(%{discord_status: "dnd"}), do: "bullet-dnd"
  defp bullet_class(_), do: "bullet-offline"

  defp status(%{connected?: false}), do: "Offline"
  defp status(%{discord_status: "online"}), do: "Online"
  defp status(%{discord_status: "idle"}), do: "Idle"
  defp status(%{discord_status: "dnd"}), do: "Do Not Disturb"
  defp status(_), do: "Offline"

  defp username(%{discord_user: %{"username" => username}}), do: username
  defp username(_), do: "vereis"

  defp activity(%{activities: [%{"name" => name} | _]}), do: name
  defp activity(_), do: nil
end
