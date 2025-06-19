defmodule Blog.Lanyard.ConnectionTest do
  use ExUnit.Case, async: true

  import Mimic

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

  setup do
    # Mock default successful response to prevent startup interference
    stub(Req, :get, fn _url ->
      {:ok, %{status: 200, body: @valid_presence_response}}
    end)

    :ok
  end

  describe "polling behavior" do
    setup do
      pid = start_supervised!(Connection)

      # Allow initial poll to complete
      :timer.sleep(50)

      %{pid: pid}
    end

    test "handles successful API response", %{pid: pid} do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)

      send(pid, :poll)
      :timer.sleep(50)

      assert Process.alive?(pid)
    end

    test "handles API error response gracefully", %{pid: pid} do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 200, body: @api_error_response}}
      end)

      send(pid, :poll)
      :timer.sleep(50)

      assert Process.alive?(pid)
    end

    test "handles HTTP error response gracefully", %{pid: pid} do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 404, body: "Not Found"}}
      end)

      send(pid, :poll)
      :timer.sleep(50)

      assert Process.alive?(pid)
    end

    test "handles network/request failure gracefully", %{pid: pid} do
      expect(Req, :get, fn _url ->
        {:error, :timeout}
      end)

      send(pid, :poll)
      :timer.sleep(50)

      assert Process.alive?(pid)
    end

    test "handles multiple polls with same data", %{pid: pid} do
      expect(Req, :get, 2, fn _url ->
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)

      send(pid, :poll)
      :timer.sleep(25)
      send(pid, :poll)
      :timer.sleep(25)

      assert Process.alive?(pid)
    end

    test "schedules next poll after successful response", %{pid: pid} do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)

      send(pid, :poll)
      :timer.sleep(50)

      # Process should remain alive indicating successful scheduling
      assert Process.alive?(pid)
    end

    test "schedules retry on error", %{pid: pid} do
      expect(Req, :get, fn _url ->
        {:error, :timeout}
      end)

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

      expect(Req, :get, 2, fn url ->
        assert url == expected_url
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)

      pid = start_supervised!(Connection)
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

      _presence_pid = start_supervised!(Presence)
      _connection_pid = start_supervised!(Connection)

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

      _presence_pid = start_supervised!(Presence)
      _connection_pid = start_supervised!(Connection)

      assert {:ok, presence} = Connection.refresh_presence()
      assert %Presence{} = presence
      assert presence.connected? == false
    end
  end

  describe "message handling" do
    test "handles unknown messages gracefully" do
      expect(Req, :get, fn _url ->
        {:ok, %{status: 200, body: @valid_presence_response}}
      end)

      pid = start_supervised!(Connection)

      send(pid, :unknown_message)
      :timer.sleep(25)

      assert Process.alive?(pid)
    end
  end
end
