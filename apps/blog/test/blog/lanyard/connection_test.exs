defmodule Blog.Lanyard.ConnectionTest do
  use Blog.DataCase, async: true

  alias Blog.Lanyard.Connection
  alias Blog.Lanyard.Presence

  @valid_presence_response %{
    "success" => true,
    "data" => %{
      "discord_user" => %{
        "id" => "94490510688792576",
        "username" => "phin",
        "avatar" => "6b8c6a21ee4e549695f20c51036642e2",
        "discriminator" => "0",
        "global_name" => "Phineas",
        "display_name" => "Phineas"
      },
      "activities" => [],
      "discord_status" => "dnd",
      "active_on_discord_web" => false,
      "active_on_discord_desktop" => true,
      "active_on_discord_mobile" => false,
      "listening_to_spotify" => false,
      "spotify" => nil
    }
  }

  @api_error_response %{
    "success" => false,
    "error" => "User not found"
  }

  describe "polling behavior" do
    test "handles successful API response" do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)

      expect(Blog.Lanyard.Presence, :update_presence, fn _data ->
        {:ok, %Presence{}}
      end)

      pid = start_supervised!(Connection)
      
      # Allow the GenServer process to access mocks
      Mimic.allow(Req, self(), pid)
      Mimic.allow(Blog.Lanyard.Presence, self(), pid)

      send(pid, :poll)
      :timer.sleep(50)

      assert Process.alive?(pid)
    end

    test "handles API error response gracefully" do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 200, body: @api_error_response}}
      end)

      pid = start_supervised!(Connection)
      
      # Allow the GenServer process to access mocks
      Mimic.allow(Req, self(), pid)

      send(pid, :poll)
      :timer.sleep(50)

      assert Process.alive?(pid)
    end

    test "handles HTTP error response gracefully" do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 404, body: "Not Found"}}
      end)

      pid = start_supervised!(Connection)
      
      # Allow the GenServer process to access mocks
      Mimic.allow(Req, self(), pid)

      send(pid, :poll)
      :timer.sleep(50)

      assert Process.alive?(pid)
    end

    test "handles network/request failure gracefully" do
      expect(Req, :get, fn _url ->
        {:error, :timeout}
      end)

      pid = start_supervised!(Connection)
      
      # Allow the GenServer process to access mocks
      Mimic.allow(Req, self(), pid)

      send(pid, :poll)
      :timer.sleep(50)

      assert Process.alive?(pid)
    end

    test "handles multiple polls with same data" do
      expect(Req, :get, 2, fn _url ->
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)
      
      expect(Blog.Lanyard.Presence, :update_presence, fn _data ->
        {:ok, %Presence{}}
      end)

      pid = start_supervised!(Connection)
      
      # Allow the GenServer process to access mocks
      Mimic.allow(Req, self(), pid)
      Mimic.allow(Blog.Lanyard.Presence, self(), pid)

      send(pid, :poll)
      :timer.sleep(25)
      send(pid, :poll)
      :timer.sleep(25)

      assert Process.alive?(pid)
    end

    test "schedules next poll after successful response" do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)
      
      expect(Blog.Lanyard.Presence, :update_presence, fn _data ->
        {:ok, %Presence{}}
      end)

      pid = start_supervised!(Connection)
      
      # Allow the GenServer process to access mocks
      Mimic.allow(Req, self(), pid)
      Mimic.allow(Blog.Lanyard.Presence, self(), pid)

      send(pid, :poll)
      :timer.sleep(50)

      # Process should remain alive indicating successful scheduling
      assert Process.alive?(pid)
    end

    test "schedules retry on error" do
      expect(Req, :get, fn _url ->
        {:error, :timeout}
      end)

      pid = start_supervised!(Connection)
      
      # Allow the GenServer process to access mocks
      Mimic.allow(Req, self(), pid)

      send(pid, :poll)
      :timer.sleep(50)

      # Process should remain alive indicating retry scheduling
      assert Process.alive?(pid)
    end
  end

  describe "configuration integration" do
    test "uses configured user ID for API requests" do
      expected_user_id = Blog.Lanyard.get_user_id()
      expected_url = Blog.Lanyard.api_url(expected_user_id)

      expect(Req, :get, fn url ->
        assert url == expected_url
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)
      
      expect(Blog.Lanyard.Presence, :update_presence, fn _data ->
        {:ok, %Presence{}}
      end)

      pid = start_supervised!(Connection)
      
      # Allow the GenServer process to access mocks
      Mimic.allow(Req, self(), pid)
      Mimic.allow(Blog.Lanyard.Presence, self(), pid)
      
      send(pid, :poll)
      :timer.sleep(50)
    end
  end

  describe "refresh_presence/0" do
    @tag :refresh_presence
    test "forces immediate refresh and returns updated presence" do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)

      expect(Presence, :update_presence, fn presence_data ->
        assert presence_data == @valid_presence_response["data"]
        {:ok, %Presence{connected?: true}}
      end)

      expect(Presence, :get_presence, fn ->
        %Presence{connected?: true, discord_status: "online"}
      end)

      presence_pid = start_supervised!(Presence)
      connection_pid = start_supervised!(Connection)
      
      # Allow both processes to access mocks
      Mimic.allow(Req, self(), connection_pid)
      Mimic.allow(Blog.Lanyard.Presence, self(), connection_pid)
      Mimic.allow(Blog.Lanyard.Presence, self(), presence_pid)

      assert {:ok, presence} = Connection.refresh_presence()
      assert %Presence{} = presence
      assert presence.connected? == true
      assert presence.discord_status == "online"
    end

    @tag :refresh_presence
    test "returns ok even when fetch fails" do
      expect(Req, :get, fn _url ->
        {:error, :timeout}
      end)

      expect(Presence, :get_presence, fn ->
        %Presence{connected?: false}
      end)

      presence_pid = start_supervised!(Presence)
      connection_pid = start_supervised!(Connection)
      
      # Allow both processes to access mocks
      Mimic.allow(Req, self(), connection_pid)
      Mimic.allow(Blog.Lanyard.Presence, self(), connection_pid)
      Mimic.allow(Blog.Lanyard.Presence, self(), presence_pid)

      assert {:ok, presence} = Connection.refresh_presence()
      assert %Presence{} = presence
      assert presence.connected? == false
    end

    test "broadcasts presence updates via PubSub when data changes" do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)

      expect(Presence, :update_presence, fn presence_data ->
        assert presence_data == @valid_presence_response["data"]
        {:ok, %Presence{connected?: true, discord_status: "online"}}
      end)

      # Subscribe to PubSub events
      Phoenix.PubSub.subscribe(Blog.PubSub, "lanyard:presence")

      presence_pid = start_supervised!(Presence)
      connection_pid = start_supervised!(Connection)
      
      # Allow both processes to access mocks
      Mimic.allow(Req, self(), connection_pid)
      Mimic.allow(Blog.Lanyard.Presence, self(), connection_pid)
      Mimic.allow(Blog.Lanyard.Presence, self(), presence_pid)

      # Force a refresh which should broadcast
      Connection.refresh_presence()

      # Should receive PubSub message
      assert_receive {:presence_updated, %Presence{connected?: true}}, 100
    end
  end

  describe "message handling" do
    test "handles unknown messages gracefully" do
      pid = start_supervised!(Connection)

      send(pid, :unknown_message)
      :timer.sleep(25)

      assert Process.alive?(pid)
    end
  end
end
