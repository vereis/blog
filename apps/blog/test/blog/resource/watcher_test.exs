defmodule Blog.Resource.WatcherTest do
  use Blog.DataCase, async: false

  alias Blog.Posts.Post
  alias Blog.Resource.Watcher

  describe "initialization" do
    test "does not trigger import in test environment on boot" do
      initial_count = length(Blog.Posts.list_posts())

      wait_for_genserver(Watcher)

      final_count = length(Blog.Posts.list_posts())
      assert final_count == initial_count
    end

    test "does not start filesystem watchers in test environment" do
      state = :sys.get_state(Watcher)
      assert state.watchers == %{}
    end
  end

  describe "file change detection" do
    test "handles file change events" do
      send(Watcher, {:file_event, make_ref(), {"test.md", [:modified]}})

      assert eventually(fn ->
               state = :sys.get_state(Watcher)
               state.timers == %{}
             end)
    end

    test "ignores invalid events" do
      initial_state = :sys.get_state(Watcher)

      send(Watcher, {:file_event, make_ref(), {"test.md", [:invalid]}})

      wait_for_genserver(Watcher)

      state = :sys.get_state(Watcher)
      assert state == initial_state
    end
  end

  describe "debouncing" do
    test "debounces rapid file changes and clears timers after execution" do
      for _ <- 1..5 do
        send(Watcher, {:file_event, make_ref(), {"dummy.md", [:modified]}})
        Process.sleep(10)
      end

      assert eventually(fn ->
               state = :sys.get_state(Watcher)
               state.timers == %{}
             end)
    end

    test "cancels and flushes already-fired timers when scheduling new import" do
      send(Watcher, {:schedule_import, Post})

      assert eventually(fn ->
               state = :sys.get_state(Watcher)
               state.timers == %{}
             end)

      send(Watcher, {:schedule_import, Post})

      wait_for_genserver(Watcher)

      state_after_second = :sys.get_state(Watcher)
      assert map_size(state_after_second.timers) == 1
    end
  end

  describe "PubSub broadcasts" do
    test "imports trigger PubSub broadcasts for resource reloads" do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")

      {:ok, posts} = Post.import()

      refute Enum.empty?(posts)

      for post <- posts do
        assert_received {:resource_reload, Post, post_id}
        assert post_id == post.id
      end
    end
  end
end
