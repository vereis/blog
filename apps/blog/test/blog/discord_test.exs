defmodule Blog.DiscordTest do
  use Blog.DataCase, async: false

  alias Blog.Discord
  alias Blog.Discord.Presence

  setup do
    # Cleanup ETS table before each test
    if :ets.whereis(:discord_presence) != :undefined do
      :ets.delete(:discord_presence)
    end

    on_exit(fn ->
      if :ets.whereis(:discord_presence) != :undefined do
        :ets.delete(:discord_presence)
      end
    end)

    :ok
  end

  describe "get_presence/0" do
    test "returns disconnected presence when ETS table doesn't exist" do
      # ETS table won't exist
      presence = Discord.get_presence()

      assert presence.connected? == false
      assert presence.discord_status == "offline"
    end

    test "returns disconnected presence when ETS table is empty" do
      :ets.new(:discord_presence, [:set, :named_table, :public, read_concurrency: true])

      presence = Discord.get_presence()

      assert presence.connected? == false
      assert presence.discord_status == "offline"
    end

    test "returns presence from ETS when it exists" do
      :ets.new(:discord_presence, [:set, :named_table, :public, read_concurrency: true])

      test_presence = %Presence{
        discord_status: "online",
        discord_user: %{"username" => "testuser"},
        listening_to_spotify: true,
        spotify: %{"song" => "Test Song"},
        connected?: true
      }

      :ets.insert(:discord_presence, {:current, test_presence})

      presence = Discord.get_presence()

      assert presence.discord_status == "online"
      assert presence.discord_user["username"] == "testuser"
      assert presence.listening_to_spotify == true
      assert presence.spotify["song"] == "Test Song"
      assert presence.connected? == true
    end

    test "handles race condition when table is deleted during lookup" do
      :ets.new(:discord_presence, [:set, :named_table, :public, read_concurrency: true])
      :ets.delete(:discord_presence)

      # Should not crash, should return disconnected
      presence = Discord.get_presence()

      assert presence.connected? == false
    end
  end

  describe "connected?/0" do
    test "returns false when not connected" do
      refute Discord.connected?()
    end

    test "returns true when connected" do
      :ets.new(:discord_presence, [:set, :named_table, :public, read_concurrency: true])

      test_presence = %Presence{connected?: true}
      :ets.insert(:discord_presence, {:current, test_presence})

      assert Discord.connected?()
    end

    test "returns false when presence is disconnected in ETS" do
      :ets.new(:discord_presence, [:set, :named_table, :public, read_concurrency: true])

      test_presence = %Presence{connected?: false}
      :ets.insert(:discord_presence, {:current, test_presence})

      refute Discord.connected?()
    end
  end

  describe "get_user_id/0" do
    test "returns configured Discord user ID" do
      assert Discord.get_user_id() == "382588737441497088"
    end
  end
end
