defmodule BlogWeb.PresenceTest do
  use ExUnit.Case, async: true

  alias BlogWeb.Presence

  describe "init/1" do
    test "returns empty state map" do
      assert {:ok, %{}} = Presence.init([])
    end
  end

  describe "handle_metas/4" do
    setup do
      # Subscribe to test topic to receive broadcasts
      topic = "test:topic:#{:erlang.unique_integer([:positive])}"
      Phoenix.PubSub.subscribe(Blog.PubSub, topic)

      {:ok, topic: topic}
    end

    test "broadcasts viewer count on joins", %{topic: topic} do
      joins = %{"user1" => %{metas: [%{phx_ref: "ref1"}]}}
      leaves = %{}
      presences = %{"user1" => %{metas: [%{phx_ref: "ref1"}]}}
      state = %{}

      assert {:ok, ^state} = Presence.handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state)

      assert_receive {:viewer_count_updated, ^topic, 1}
      assert_receive {:viewer_joined, ^topic}
    end

    test "broadcasts viewer count on leaves", %{topic: topic} do
      joins = %{}
      leaves = %{"user1" => %{metas: [%{phx_ref: "ref1"}]}}
      presences = %{}
      state = %{}

      assert {:ok, ^state} = Presence.handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state)

      assert_receive {:viewer_count_updated, ^topic, 0}
      assert_receive {:viewer_left, ^topic}
    end

    test "broadcasts correct count with multiple users", %{topic: topic} do
      joins = %{
        "user2" => %{metas: [%{phx_ref: "ref2"}]}
      }

      leaves = %{}

      presences = %{
        "user1" => %{metas: [%{phx_ref: "ref1"}]},
        "user2" => %{metas: [%{phx_ref: "ref2"}]}
      }

      state = %{}

      assert {:ok, ^state} = Presence.handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state)

      assert_receive {:viewer_count_updated, ^topic, 2}
    end

    test "broadcasts multiple join events for multiple users", %{topic: topic} do
      joins = %{
        "user1" => %{metas: [%{phx_ref: "ref1"}]},
        "user2" => %{metas: [%{phx_ref: "ref2"}]}
      }

      leaves = %{}

      presences = %{
        "user1" => %{metas: [%{phx_ref: "ref1"}]},
        "user2" => %{metas: [%{phx_ref: "ref2"}]}
      }

      state = %{}

      assert {:ok, ^state} = Presence.handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state)

      assert_receive {:viewer_joined, ^topic}
      assert_receive {:viewer_joined, ^topic}
    end

    test "broadcasts both joins and leaves", %{topic: topic} do
      joins = %{"user2" => %{metas: [%{phx_ref: "ref2"}]}}
      leaves = %{"user1" => %{metas: [%{phx_ref: "ref1"}]}}
      presences = %{"user2" => %{metas: [%{phx_ref: "ref2"}]}}
      state = %{}

      assert {:ok, ^state} = Presence.handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state)

      assert_receive {:viewer_count_updated, ^topic, 1}
      assert_receive {:viewer_joined, ^topic}
      assert_receive {:viewer_left, ^topic}
    end
  end
end
