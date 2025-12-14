defmodule Blog.Discord.PresenceTest do
  use ExUnit.Case, async: true

  alias Blog.Discord.Presence

  describe "from_api_data/1" do
    test "creates presence from valid API data" do
      api_data = %{
        "discord_user" => %{"id" => "123", "username" => "test"},
        "discord_status" => "online",
        "activities" => [%{"name" => "Coding"}],
        "active_on_discord_web" => true,
        "active_on_discord_desktop" => false,
        "active_on_discord_mobile" => true,
        "listening_to_spotify" => true,
        "spotify" => %{"song" => "Test Song"}
      }

      presence = Presence.from_api_data(api_data)

      assert presence.discord_user == %{"id" => "123", "username" => "test"}
      assert presence.discord_status == "online"
      assert presence.activities == [%{"name" => "Coding"}]
      assert presence.active_on_discord_web == true
      assert presence.active_on_discord_desktop == false
      assert presence.active_on_discord_mobile == true
      assert presence.listening_to_spotify == true
      assert presence.spotify == %{"song" => "Test Song"}
      assert presence.connected? == true
    end

    test "handles missing fields with defaults" do
      presence = Presence.from_api_data(%{})

      assert presence.discord_user == nil
      assert presence.discord_status == "offline"
      assert presence.activities == []
      assert presence.active_on_discord_web == false
      assert presence.active_on_discord_desktop == false
      assert presence.active_on_discord_mobile == false
      assert presence.listening_to_spotify == false
      assert presence.spotify == nil
      assert presence.connected? == true
    end

    test "handles nil values in API data" do
      api_data = %{
        "discord_user" => nil,
        "discord_status" => nil,
        "activities" => nil,
        "spotify" => nil
      }

      presence = Presence.from_api_data(api_data)

      assert presence.discord_user == nil
      assert presence.discord_status == "offline"
      assert presence.activities == []
      assert presence.spotify == nil
    end
  end

  describe "disconnected/0" do
    test "returns disconnected presence with defaults" do
      presence = Presence.disconnected()

      assert presence.connected? == false
      assert presence.discord_status == "offline"
      assert presence.discord_user == nil
      assert presence.activities == []
      assert presence.listening_to_spotify == false
      assert presence.spotify == nil
    end
  end

  describe "handle_connect/2" do
    setup do
      # Cleanup any existing table
      if :ets.whereis(:discord_presence) != :undefined do
        :ets.delete(:discord_presence)
      end

      :ok
    end

    test "creates ETS table on first connection" do
      state = %Presence.State{heartbeat_timer: nil, heartbeat_interval: nil}

      assert {:ok, ^state} = Presence.handle_connect(%{}, state)
      assert :ets.whereis(:discord_presence) != :undefined

      # Cleanup
      :ets.delete(:discord_presence)
    end

    test "does not crash when ETS table already exists (reconnection scenario)" do
      # Create table first
      :ets.new(:discord_presence, [:set, :named_table, :public, read_concurrency: true])

      state = %Presence.State{heartbeat_timer: nil, heartbeat_interval: nil}

      # Should not crash on second connect
      assert {:ok, ^state} = Presence.handle_connect(%{}, state)
      assert :ets.whereis(:discord_presence) != :undefined

      # Cleanup
      :ets.delete(:discord_presence)
    end

    test "ETS table has correct properties" do
      state = %Presence.State{heartbeat_timer: nil, heartbeat_interval: nil}
      {:ok, _} = Presence.handle_connect(%{}, state)

      info = :ets.info(:discord_presence)

      assert info[:type] == :set
      assert info[:named_table] == true
      assert info[:protection] == :public
      assert info[:read_concurrency] == true

      # Cleanup
      :ets.delete(:discord_presence)
    end
  end

  describe "handle_frame/2 - Opcode 1 (Hello)" do
    test "starts heartbeat and sends Initialize message" do
      state = %Presence.State{heartbeat_timer: nil, heartbeat_interval: nil}

      hello_msg =
        Jason.encode!(%{
          "op" => 1,
          "d" => %{"heartbeat_interval" => 30_000}
        })

      assert {:reply, {:text, reply_msg}, new_state} = Presence.handle_frame({:text, hello_msg}, state)

      # Check state updated
      assert new_state.heartbeat_interval == 30_000
      assert new_state.heartbeat_timer

      # Check Initialize message sent
      reply_data = Jason.decode!(reply_msg)
      assert reply_data["op"] == 2
      assert reply_data["d"]["subscribe_to_id"] == "382588737441497088"

      # Cleanup timer
      Process.cancel_timer(new_state.heartbeat_timer)
    end

    test "cancels existing heartbeat timer before creating new one" do
      existing_timer = Process.send_after(self(), :old_heartbeat, 10_000)
      state = %Presence.State{heartbeat_timer: existing_timer, heartbeat_interval: 10_000}

      hello_msg =
        Jason.encode!(%{
          "op" => 1,
          "d" => %{"heartbeat_interval" => 30_000}
        })

      {:reply, _, new_state} = Presence.handle_frame({:text, hello_msg}, state)

      # Old timer should be cancelled
      assert new_state.heartbeat_timer != existing_timer

      # Cleanup
      Process.cancel_timer(new_state.heartbeat_timer)
    end
  end

  describe "handle_frame/2 - INIT_STATE and PRESENCE_UPDATE" do
    setup do
      # Create ETS table for these tests
      if :ets.whereis(:discord_presence) != :undefined do
        :ets.delete(:discord_presence)
      end

      :ets.new(:discord_presence, [:set, :named_table, :public, read_concurrency: true])

      on_exit(fn ->
        if :ets.whereis(:discord_presence) != :undefined do
          :ets.delete(:discord_presence)
        end
      end)

      :ok
    end

    test "handles INIT_STATE and updates ETS" do
      state = %Presence.State{heartbeat_timer: nil, heartbeat_interval: nil}

      init_msg =
        Jason.encode!(%{
          "op" => 0,
          "t" => "INIT_STATE",
          "d" => %{
            "discord_status" => "online",
            "discord_user" => %{"username" => "testuser"}
          }
        })

      assert {:ok, ^state} = Presence.handle_frame({:text, init_msg}, state)

      # Check ETS was updated
      [{:current, presence}] = :ets.lookup(:discord_presence, :current)
      assert presence.discord_status == "online"
      assert presence.discord_user["username"] == "testuser"
      assert presence.connected? == true
    end

    test "handles PRESENCE_UPDATE and updates ETS" do
      state = %Presence.State{heartbeat_timer: nil, heartbeat_interval: nil}

      update_msg =
        Jason.encode!(%{
          "op" => 0,
          "t" => "PRESENCE_UPDATE",
          "d" => %{
            "discord_status" => "dnd",
            "listening_to_spotify" => true,
            "spotify" => %{"song" => "Cool Song"}
          }
        })

      assert {:ok, ^state} = Presence.handle_frame({:text, update_msg}, state)

      # Check ETS was updated
      [{:current, presence}] = :ets.lookup(:discord_presence, :current)
      assert presence.discord_status == "dnd"
      assert presence.listening_to_spotify == true
      assert presence.spotify == %{"song" => "Cool Song"}
    end
  end

  describe "handle_frame/2 - error handling" do
    test "handles unknown message types gracefully" do
      state = %Presence.State{heartbeat_timer: nil, heartbeat_interval: nil}

      unknown_msg =
        Jason.encode!(%{
          "op" => 99,
          "t" => "UNKNOWN_EVENT"
        })

      assert {:ok, ^state} = Presence.handle_frame({:text, unknown_msg}, state)
    end

    @tag :capture_log
    test "handles invalid JSON gracefully" do
      state = %Presence.State{heartbeat_timer: nil, heartbeat_interval: nil}

      assert {:ok, ^state} = Presence.handle_frame({:text, "not valid json"}, state)
    end
  end

  describe "handle_info/2 - heartbeat" do
    test "sends heartbeat and schedules next one" do
      state = %Presence.State{heartbeat_timer: nil, heartbeat_interval: 30_000}

      assert {:reply, {:text, heartbeat_msg}, new_state} = Presence.handle_info(:heartbeat, state)

      # Check heartbeat message
      assert %{"op" => 3} = Jason.decode!(heartbeat_msg)

      # Check next heartbeat scheduled
      assert new_state.heartbeat_timer

      # Cleanup
      Process.cancel_timer(new_state.heartbeat_timer)
    end
  end

  describe "handle_disconnect/2" do
    @tag :capture_log
    test "cancels heartbeat timer and returns reconnect" do
      timer = Process.send_after(self(), :heartbeat, 10_000)
      state = %Presence.State{heartbeat_timer: timer, heartbeat_interval: 30_000}

      assert {:reconnect, new_state} = Presence.handle_disconnect(%{reason: :normal}, state)

      # Timer should be cleared
      assert new_state.heartbeat_timer == nil
      assert new_state.heartbeat_interval == 30_000
    end

    @tag :capture_log
    test "handles disconnect when no timer exists" do
      state = %Presence.State{heartbeat_timer: nil, heartbeat_interval: 30_000}

      assert {:reconnect, new_state} = Presence.handle_disconnect(%{reason: :normal}, state)
      assert new_state.heartbeat_timer == nil
    end
  end
end
