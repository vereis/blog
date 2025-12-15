defmodule BlogWeb.Components.DiscordTest do
  use BlogWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Blog.Discord.Presence
  alias BlogWeb.Components.Aside.Discord

  describe "presence/1" do
    test "renders online status with colored bullet" do
      presence = %Presence{
        discord_status: "online",
        discord_user: %{"username" => "testuser"},
        connected?: true
      }

      assigns = %{presence: presence}

      html = render_component(&Discord.presence/1, assigns)

      assert html =~ "bullet-online"
      assert html =~ "testuser"
      assert html =~ "Online"
    end

    test "renders idle status" do
      presence = %Presence{discord_status: "idle", connected?: true}
      assigns = %{presence: presence}

      html = render_component(&Discord.presence/1, assigns)

      assert html =~ "bullet-idle"
      assert html =~ "Idle"
    end

    test "renders dnd status" do
      presence = %Presence{discord_status: "dnd", connected?: true}
      assigns = %{presence: presence}

      html = render_component(&Discord.presence/1, assigns)

      assert html =~ "bullet-dnd"
      assert html =~ "Do Not Disturb"
    end

    test "renders offline status when disconnected" do
      presence = Presence.disconnected()
      assigns = %{presence: presence}

      html = render_component(&Discord.presence/1, assigns)

      assert html =~ "bullet-offline"
      assert html =~ "Offline"
      assert html =~ "vereis"
    end

    test "renders with default username when no discord_user" do
      presence = %Presence{
        connected?: true,
        discord_user: nil,
        discord_status: "online"
      }

      assigns = %{presence: presence}

      html = render_component(&Discord.presence/1, assigns)

      assert html =~ "vereis"
    end

    test "renders activity when present" do
      presence = %Presence{
        connected?: true,
        discord_status: "online",
        activities: [%{"name" => "Coding"}]
      }

      assigns = %{presence: presence}

      html = render_component(&Discord.presence/1, assigns)

      assert html =~ "Coding"
    end

    test "does not render activity when disconnected" do
      presence = %Presence{
        connected?: false,
        activities: [%{"name" => "Coding"}]
      }

      assigns = %{presence: presence}

      html = render_component(&Discord.presence/1, assigns)

      refute html =~ "Coding"
    end

    test "renders Spotify when listening" do
      presence = %Presence{
        connected?: true,
        discord_status: "online",
        listening_to_spotify: true,
        spotify: %{"song" => "Test Song", "artist" => "Test Artist"}
      }

      assigns = %{presence: presence}

      html = render_component(&Discord.presence/1, assigns)

      assert html =~ "Test Song"
      assert html =~ "Test Artist"
      assert html =~ "—"
    end

    test "renders full presence with activity and spotify" do
      presence = %Presence{
        connected?: true,
        discord_user: %{"username" => "testuser"},
        discord_status: "online",
        activities: [%{"name" => "Coding"}],
        listening_to_spotify: true,
        spotify: %{"song" => "Test Song", "artist" => "Test Artist"}
      }

      assigns = %{presence: presence}

      html = render_component(&Discord.presence/1, assigns)

      assert html =~ "testuser"
      assert html =~ "Online"
      assert html =~ "Coding"
      assert html =~ "Test Song"
      assert html =~ "Test Artist"
    end

    test "applies custom id" do
      presence = Presence.disconnected()
      assigns = %{presence: presence, id: "my-custom-id"}

      html = render_component(&Discord.presence/1, assigns)

      assert html =~ "my-custom-id"
    end
  end
end
