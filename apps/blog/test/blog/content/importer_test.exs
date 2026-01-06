defmodule Blog.Content.ImporterTest do
  use Blog.DataCase, async: false

  alias Blog.Content.Importer
  alias Blog.Posts.Post

  setup do
    start_supervised!(Importer)
    :ok
  end

  describe "initialization" do
    test "does not trigger import in test environment on boot" do
      initial_count = length(Blog.Posts.list_posts())

      wait_for_genserver(Importer)

      final_count = length(Blog.Posts.list_posts())
      assert final_count == initial_count
    end

    test "does not start filesystem watchers in test environment" do
      state = :sys.get_state(Importer)
      assert is_nil(state.watcher_pid)
    end
  end

  describe "content_path/0" do
    test "returns test fixtures path in test environment" do
      path = Importer.content_path()
      assert path =~ "test/fixtures/priv/content"
    end
  end

  describe "import_all/0" do
    @tag :capture_log
    test "imports all content types in correct order" do
      assert :ok = Importer.import_all()

      refute Enum.empty?(Blog.Assets.list_assets())
      refute Enum.empty?(Blog.Posts.list_posts())
      refute Enum.empty?(Blog.Projects.list_projects())
    end
  end

  describe "file change detection" do
    test "handles file change events" do
      send(Importer, {:file_event, make_ref(), {"test.md", [:modified]}})

      assert eventually(fn ->
               state = :sys.get_state(Importer)
               is_nil(state.timer_ref)
             end)
    end

    test "ignores invalid events" do
      initial_state = :sys.get_state(Importer)

      send(Importer, {:file_event, make_ref(), {"test.md", [:invalid]}})

      wait_for_genserver(Importer)

      state = :sys.get_state(Importer)
      assert state.timer_ref == initial_state.timer_ref
    end
  end

  describe "debouncing" do
    test "debounces rapid file changes and clears timer after execution" do
      for _ <- 1..5 do
        send(Importer, {:file_event, make_ref(), {"dummy.md", [:modified]}})
        Process.sleep(10)
      end

      assert eventually(fn ->
               state = :sys.get_state(Importer)
               is_nil(state.timer_ref)
             end)
    end
  end

  describe "PubSub broadcasts" do
    @tag :capture_log
    test "imports trigger PubSub broadcasts for content reloads" do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")

      {:ok, posts} = Post.import()

      refute Enum.empty?(posts)

      for post <- posts do
        assert_received {:content_reload, Post, post_id}
        assert post_id == post.id
      end
    end
  end
end
