defmodule BlogWeb.Components.ViewersTest do
  use BlogWeb.ConnCase, async: true

  alias BlogWeb.Components.Aside.Viewers

  setup do
    # Generate unique topics for each test to avoid conflicts
    base_topic = "test:viewers:#{:erlang.unique_integer([:positive])}"

    {:ok, topic: base_topic}
  end

  describe "track_viewer/4" do
    test "tracks a viewer on a topic", %{topic: topic} do
      key = "user123"

      assert {:ok, _ref} = Viewers.track_viewer(self(), topic, key)

      # Verify the viewer is tracked by checking presence directly
      assert topic |> BlogWeb.Presence.list() |> map_size() == 1
    end

    test "tracks multiple viewers on the same topic", %{topic: topic} do
      assert {:ok, _} = Viewers.track_viewer(self(), topic, "user1")
      assert {:ok, _} = Viewers.track_viewer(self(), topic, "user2")

      assert topic |> BlogWeb.Presence.list() |> map_size() == 2
    end

    test "accepts metadata", %{topic: topic} do
      meta = %{joined_at: System.system_time()}

      assert {:ok, _ref} = Viewers.track_viewer(self(), topic, "user1", meta)
      assert topic |> BlogWeb.Presence.list() |> map_size() == 1
    end
  end

  describe "untrack_viewer/3" do
    test "untracks a viewer from a topic", %{topic: topic} do
      key = "user123"

      {:ok, _} = Viewers.track_viewer(self(), topic, key)
      assert topic |> BlogWeb.Presence.list() |> map_size() == 1

      :ok = Viewers.untrack_viewer(self(), topic, key)

      # Use sys.get_state to ensure presence has processed the untrack
      _ = :sys.get_state(BlogWeb.Presence)

      assert topic |> BlogWeb.Presence.list() |> map_size() == 0
    end

    test "only untracks the specified viewer", %{topic: topic} do
      {:ok, _} = Viewers.track_viewer(self(), topic, "user1")
      {:ok, _} = Viewers.track_viewer(self(), topic, "user2")

      :ok = Viewers.untrack_viewer(self(), topic, "user1")
      _ = :sys.get_state(BlogWeb.Presence)

      assert topic |> BlogWeb.Presence.list() |> map_size() == 1
    end
  end

  describe "count/0" do
    test "returns 0 when no site-wide viewers" do
      assert Viewers.count() == 0
    end

    test "returns correct site-wide viewer count" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.site_topic(), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.site_topic(), "user2")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.site_topic(), "user3")

      assert Viewers.count() == 3
    end

    test "site-wide count is independent of page counts" do
      # Track on site
      {:ok, _} = Viewers.track_viewer(self(), Viewers.site_topic(), "user1")

      # Track on different pages
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:home), "user2")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:posts), "user3")

      # Site count should only be 1
      assert Viewers.count() == 1
    end
  end

  describe "count/1 with atom" do
    test "returns 0 for empty home page" do
      assert Viewers.count(:home) == 0
    end

    test "returns correct count for home page" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:home), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:home), "user2")

      assert Viewers.count(:home) == 2
    end

    test "returns 0 for empty posts page" do
      assert Viewers.count(:posts) == 0
    end

    test "returns correct count for posts page" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:posts), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:posts), "user2")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:posts), "user3")

      assert Viewers.count(:posts) == 3
    end

    test "returns 0 for empty projects page" do
      assert Viewers.count(:projects) == 0
    end

    test "returns correct count for projects page" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:projects), "user1")

      assert Viewers.count(:projects) == 1
    end

    test "returns 0 for empty gallery page" do
      assert Viewers.count(:gallery) == 0
    end

    test "returns correct count for gallery page" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:gallery), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:gallery), "user2")

      assert Viewers.count(:gallery) == 2
    end

    test "page counts are independent of each other" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:home), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:posts), "user2")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:posts), "user3")

      assert Viewers.count(:home) == 1
      assert Viewers.count(:posts) == 2
      assert Viewers.count(:projects) == 0
    end
  end

  describe "count/1 with keyword list - posts: []" do
    test "returns 0 for empty posts list" do
      assert Viewers.count(posts: []) == 0
    end

    test "returns correct count for posts list" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:posts), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:posts), "user2")

      assert Viewers.count(posts: []) == 2
    end

    test "posts: [] is equivalent to :posts atom" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:posts), "user1")

      assert Viewers.count(posts: []) == Viewers.count(:posts)
      assert Viewers.count(posts: []) == 1
    end
  end

  describe "count/1 with keyword list - posts: slug" do
    test "returns 0 for empty individual post" do
      assert Viewers.count(posts: "hello-world") == 0
    end

    test "returns correct count for individual post" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.post_topic("hello-world"), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.post_topic("hello-world"), "user2")

      assert Viewers.count(posts: "hello-world") == 2
    end

    test "different post slugs have independent counts" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.post_topic("post-1"), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.post_topic("post-2"), "user2")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.post_topic("post-2"), "user3")

      assert Viewers.count(posts: "post-1") == 1
      assert Viewers.count(posts: "post-2") == 2
      assert Viewers.count(posts: "post-3") == 0
    end

    test "individual post count is independent of posts list count" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:posts), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.post_topic("about"), "user2")

      assert Viewers.count(:posts) == 1
      assert Viewers.count(posts: "about") == 1
      assert Viewers.count(posts: "other") == 0
    end
  end

  describe "count/1 with keyword list - projects: []" do
    test "returns 0 for empty projects list" do
      assert Viewers.count(projects: []) == 0
    end

    test "returns correct count for projects list" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:projects), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:projects), "user2")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:projects), "user3")

      assert Viewers.count(projects: []) == 3
    end

    test "projects: [] is equivalent to :projects atom" do
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:projects), "user1")
      {:ok, _} = Viewers.track_viewer(self(), Viewers.page_topic(:projects), "user2")

      assert Viewers.count(projects: []) == Viewers.count(:projects)
      assert Viewers.count(projects: []) == 2
    end
  end

  describe "count/1 edge cases and error handling" do
    test "raises ArgumentError for multi-element keyword lists" do
      assert_raise ArgumentError, ~r/only accepts single-element keyword lists/, fn ->
        Viewers.count(posts: "slug", projects: [])
      end
    end

    test "raises ArgumentError for empty keyword list" do
      assert_raise ArgumentError, ~r/only accepts single-element keyword lists/, fn ->
        Viewers.count([])
      end
    end

    test "raises ArgumentError for invalid keyword list format with non-atom key" do
      assert_raise ArgumentError, ~r/Invalid count\/1 keyword list format/, fn ->
        Viewers.count([{"string_key", []}])
      end
    end

    test "raises ArgumentError for invalid keyword list format with non-list/non-binary value" do
      assert_raise ArgumentError, ~r/Invalid count\/1 keyword list format/, fn ->
        Viewers.count(posts: 123)
      end
    end

    test "works with any page type atom via keyword list" do
      {:ok, _} =
        Viewers.track_viewer(self(), Viewers.page_topic(:custom_page), "user1")

      assert Viewers.count(custom_page: []) == 1
    end

    test "works with any resource type via keyword list" do
      {:ok, _} =
        Viewers.track_viewer(self(), Viewers.resource_topic(:custom, "id"), "user1")

      assert Viewers.count(custom: "id") == 1
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
      assert Viewers.post_topic("hello-world") == "viewers:page:posts:hello-world"
    end

    test "handles different slug formats" do
      assert Viewers.post_topic("my-awesome-post") == "viewers:page:posts:my-awesome-post"
      assert Viewers.post_topic("2024-01-15-post") == "viewers:page:posts:2024-01-15-post"
    end
  end

  describe "resource_topic/2" do
    test "returns topic for posts with slug" do
      assert Viewers.resource_topic(:posts, "hello-world") == "viewers:page:posts:hello-world"
    end

    test "returns topic for projects with identifier" do
      assert Viewers.resource_topic(:projects, "my-project") == "viewers:page:projects:my-project"
    end

    test "works with any page type" do
      assert Viewers.resource_topic(:custom, "identifier") == "viewers:page:custom:identifier"
    end
  end
end
