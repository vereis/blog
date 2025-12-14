defmodule BlogWeb.ViewersTest do
  use BlogWeb.ConnCase, async: true

  alias BlogWeb.Viewers

  setup do
    # Generate unique topics for each test to avoid conflicts
    base_topic = "test:viewers:#{:erlang.unique_integer([:positive])}"

    {:ok, topic: base_topic}
  end

  describe "track_viewer/4" do
    test "tracks a viewer on a topic", %{topic: topic} do
      key = "user123"

      assert {:ok, _ref} = Viewers.track_viewer(self(), topic, key)

      # Verify the viewer is tracked
      assert Viewers.get_viewer_count(topic) == 1
    end

    test "tracks multiple viewers on the same topic", %{topic: topic} do
      assert {:ok, _} = Viewers.track_viewer(self(), topic, "user1")
      assert {:ok, _} = Viewers.track_viewer(self(), topic, "user2")

      assert Viewers.get_viewer_count(topic) == 2
    end

    test "accepts metadata", %{topic: topic} do
      meta = %{joined_at: System.system_time()}

      assert {:ok, _ref} = Viewers.track_viewer(self(), topic, "user1", meta)
      assert Viewers.get_viewer_count(topic) == 1
    end
  end

  describe "untrack_viewer/3" do
    test "untracks a viewer from a topic", %{topic: topic} do
      key = "user123"

      {:ok, _} = Viewers.track_viewer(self(), topic, key)
      assert Viewers.get_viewer_count(topic) == 1

      :ok = Viewers.untrack_viewer(self(), topic, key)

      # Use sys.get_state to ensure presence has processed the untrack
      _ = :sys.get_state(BlogWeb.Presence)

      assert Viewers.get_viewer_count(topic) == 0
    end

    test "only untracks the specified viewer", %{topic: topic} do
      {:ok, _} = Viewers.track_viewer(self(), topic, "user1")
      {:ok, _} = Viewers.track_viewer(self(), topic, "user2")

      :ok = Viewers.untrack_viewer(self(), topic, "user1")
      _ = :sys.get_state(BlogWeb.Presence)

      assert Viewers.get_viewer_count(topic) == 1
    end
  end

  describe "get_viewer_count/1" do
    test "returns 0 for empty topic", %{topic: topic} do
      assert Viewers.get_viewer_count(topic) == 0
    end

    test "returns correct count for topic with viewers", %{topic: topic} do
      {:ok, _} = Viewers.track_viewer(self(), topic, "user1")
      {:ok, _} = Viewers.track_viewer(self(), topic, "user2")
      {:ok, _} = Viewers.track_viewer(self(), topic, "user3")

      assert Viewers.get_viewer_count(topic) == 3
    end
  end

  describe "get_all_counts/0" do
    test "returns map with all topic counts" do
      counts = Viewers.get_all_counts()

      assert is_map(counts)
      assert Map.has_key?(counts, :site)
      assert Map.has_key?(counts, :home)
      assert Map.has_key?(counts, :posts)
      assert Map.has_key?(counts, :projects)
      assert Map.has_key?(counts, :gallery)

      assert is_integer(counts.site)
      assert is_integer(counts.home)
      assert is_integer(counts.posts)
      assert is_integer(counts.projects)
      assert is_integer(counts.gallery)
    end
  end

  describe "subscribe/1" do
    test "subscribes to topic updates", %{topic: topic} do
      assert :ok = Viewers.subscribe(topic)

      # Track a viewer to trigger a broadcast
      {:ok, _} = Viewers.track_viewer(self(), topic, "user1")

      # Should receive presence update messages
      assert_receive {:viewer_count_updated, ^topic, 1}, 500
      assert_receive {:viewer_joined, ^topic}, 500
    end

    test "receives leave events", %{topic: topic} do
      assert :ok = Viewers.subscribe(topic)

      {:ok, _} = Viewers.track_viewer(self(), topic, "user1")
      assert_receive {:viewer_count_updated, ^topic, 1}, 500

      :ok = Viewers.untrack_viewer(self(), topic, "user1")
      assert_receive {:viewer_count_updated, ^topic, 0}, 500
      assert_receive {:viewer_left, ^topic}, 500
    end
  end

  describe "site_topic/0" do
    test "returns site-wide topic string" do
      assert Viewers.site_topic() == "viewers:site"
    end
  end

  describe "page_topic/1" do
    test "returns correct topic for home page" do
      assert Viewers.page_topic(:home) == "viewers:page:home"
    end

    test "returns correct topic for posts page" do
      assert Viewers.page_topic(:posts) == "viewers:page:posts"
    end

    test "returns correct topic for projects page" do
      assert Viewers.page_topic(:projects) == "viewers:page:projects"
    end

    test "returns correct topic for gallery page" do
      assert Viewers.page_topic(:gallery) == "viewers:page:gallery"
    end
  end

  describe "post_topic/1" do
    test "returns topic for specific post by slug" do
      assert Viewers.post_topic("hello-world") == "viewers:page:post:hello-world"
    end

    test "handles different slug formats" do
      assert Viewers.post_topic("my-awesome-post") == "viewers:page:post:my-awesome-post"
      assert Viewers.post_topic("2024-01-15-post") == "viewers:page:post:2024-01-15-post"
    end
  end
end
