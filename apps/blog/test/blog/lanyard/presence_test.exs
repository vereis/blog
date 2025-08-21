defmodule Blog.Lanyard.PresenceTest do
  use Blog.DataCase, async: true

  import ExUnit.CaptureLog

  alias Blog.Lanyard.Presence

  @sample_api_data %{
    "discord_user" => %{
      "id" => "382588737441497088",
      "username" => "vereis",
      "discriminator" => "0",
      "global_name" => "vereis",
      "display_name" => "vereis"
    },
    "activities" => [],
    "discord_status" => "online",
    "active_on_discord_web" => false,
    "active_on_discord_desktop" => true,
    "active_on_discord_mobile" => false,
    "listening_to_spotify" => false,
    "spotify" => nil
  }

  describe "start_link/1" do
    test "starts GenServer successfully" do
      pid = start_supervised!(Presence)
      assert Process.alive?(pid)
    end

    test "creates ETS table with correct properties" do
      _pid = start_supervised!(Presence)

      # Verify table exists
      assert :ets.info(Presence) != :undefined

      # Verify table properties
      table_info = :ets.info(Presence)
      assert Keyword.get(table_info, :type) == :set
      assert Keyword.get(table_info, :protection) == :public
      assert Keyword.get(table_info, :read_concurrency) == true
    end
  end

  describe "update_presence/1" do
    setup do
      pid = start_supervised!(Presence)
      %{pid: pid}
    end

    test "stores presence data in ETS table as struct and returns it" do
      assert {:ok, returned_data} = Presence.update_presence(@sample_api_data)

      assert %Presence{} = returned_data
      assert returned_data.discord_user == @sample_api_data["discord_user"]
      assert returned_data.discord_status == @sample_api_data["discord_status"]
      assert returned_data.activities == @sample_api_data["activities"]
      assert returned_data.connected? == true

      stored_data = Presence.get_presence()
      assert stored_data == returned_data
    end

    test "overwrites existing presence data" do
      # Store initial data
      assert {:ok, _data} = Presence.update_presence(@sample_api_data)

      data = Presence.get_presence()
      assert data.discord_status == "online"

      # Update with new data
      updated_api_data = put_in(@sample_api_data, ["discord_status"], "dnd")
      assert {:ok, updated_data} = Presence.update_presence(updated_api_data)

      stored_data = Presence.get_presence()
      assert stored_data.discord_status == "dnd"
      assert stored_data == updated_data
    end

    test "is synchronous - blocks until complete" do
      # This test verifies the synchronous nature by ensuring immediate consistency
      assert {:ok, returned_data} = Presence.update_presence(@sample_api_data)

      # Should be immediately available and identical
      stored_data = Presence.get_presence()
      assert stored_data == returned_data
    end
  end

  describe "get_presence/0" do
    setup do
      pid = start_supervised!(Presence)
      %{pid: pid}
    end

    test "returns disconnected presence when no data exists" do
      presence_data = Presence.get_presence()
      assert %Presence{} = presence_data
      assert presence_data.connected? == false
      assert presence_data.discord_status == "offline"
    end

    test "returns presence data struct when it exists" do
      {:ok, _} = Presence.update_presence(@sample_api_data)

      presence_data = Presence.get_presence()
      assert %Presence{} = presence_data
      assert presence_data.discord_user == @sample_api_data["discord_user"]
      assert presence_data.connected? == true
    end

    test "can be called concurrently without messaging GenServer" do
      {:ok, _} = Presence.update_presence(@sample_api_data)

      # Spawn multiple processes to read concurrently
      tasks =
        for _ <- 1..10 do
          Task.async(fn -> Presence.get_presence() end)
        end

      results = Task.await_many(tasks)

      # All should succeed with same data
      for result <- results do
        assert %Presence{} = result
        assert result.discord_user == @sample_api_data["discord_user"]
        assert result.connected? == true
      end
    end
  end

  describe "has_presence?/0" do
    setup do
      pid = start_supervised!(Presence)
      %{pid: pid}
    end

    test "returns false when no connected presence data exists" do
      refute Presence.has_presence?()
    end

    test "returns true when connected presence data exists" do
      {:ok, _} = Presence.update_presence(@sample_api_data)
      assert Presence.has_presence?()
    end
  end

  describe "Presence struct" do
    test "from_api_data/1 converts API data to struct" do
      result = Presence.from_api_data(@sample_api_data)

      assert %Presence{} = result
      assert result.discord_user == @sample_api_data["discord_user"]
      assert result.discord_status == @sample_api_data["discord_status"]
      assert result.activities == @sample_api_data["activities"]
      assert result.active_on_discord_desktop == @sample_api_data["active_on_discord_desktop"]
      assert result.listening_to_spotify == @sample_api_data["listening_to_spotify"]
      assert result.spotify == @sample_api_data["spotify"]
      assert result.connected? == true
    end

    test "from_api_data/1 handles missing optional fields" do
      minimal_data = %{
        "discord_user" => @sample_api_data["discord_user"],
        "discord_status" => "online",
        "activities" => []
      }

      result = Presence.from_api_data(minimal_data)

      assert %Presence{} = result
      assert result.discord_user == minimal_data["discord_user"]
      assert result.discord_status == "online"
      assert result.activities == []
      assert result.active_on_discord_desktop == false
      assert result.listening_to_spotify == false
      assert result.spotify == nil
      assert result.connected? == true
    end

    test "disconnected/0 returns a disconnected presence" do
      result = Presence.disconnected()

      assert %Presence{} = result
      assert result.connected? == false
      assert result.discord_status == "offline"
      assert result.discord_user == nil
    end
  end

  describe "error handling" do
    setup do
      pid = start_supervised!(Presence)
      %{pid: pid}
    end

    test "handles unknown call messages gracefully" do
      # Send unknown call - should return error
      assert capture_log(fn ->
               assert {:error, :unknown_call} = GenServer.call(Presence, :unknown_message)
             end) =~ ":unknown_message"

      # GenServer should still be alive
      assert Process.alive?(Process.whereis(Presence))
    end

    test "handles unknown cast messages gracefully" do
      # Send unknown cast - should not crash
      GenServer.cast(Presence, :unknown_message)

      # Give it time to process the cast message
      :timer.sleep(100)

      # GenServer should still be alive
      assert Process.alive?(Process.whereis(Presence))
    end

    test "handles unknown info messages gracefully" do
      # Send unknown info message - should not crash
      assert eventually(fn ->
               log = capture_log(fn -> send(Process.whereis(Presence), :unknown_message) end)
               String.contains?(log, "Unhandled info message")
             end)

      # GenServer should still be alive
      assert Process.alive?(Process.whereis(Presence))
    end
  end
end
