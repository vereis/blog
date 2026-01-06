defmodule Blog.Content.ImporterTest do
  use Blog.DataCase, async: false

  import ExUnit.CaptureLog

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
    test "imports all content types and logs errors for invalid assets" do
      log =
        capture_log(fn ->
          assert :ok = Importer.import_all()
        end)

      assert log =~ "Invalid imports detected for Blog.Assets.Asset"
      assert log =~ "Asset type handling not implemented"
      assert log =~ "Failed to load image"

      refute Enum.empty?(Blog.Assets.list_assets())
      refute Enum.empty?(Blog.Posts.list_posts())
      refute Enum.empty?(Blog.Projects.list_projects())
    end
  end

  describe "file change detection" do
    test "handles file change events and triggers import" do
      capture_log(fn ->
        send(Importer, {:file_event, make_ref(), {"test.md", [:modified]}})

        assert eventually(fn ->
                 state = :sys.get_state(Importer)
                 is_nil(state.timer_ref)
               end)
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
      capture_log(fn ->
        for _ <- 1..5 do
          send(Importer, {:file_event, make_ref(), {"dummy.md", [:modified]}})
          Process.sleep(10)
        end

        assert eventually(fn ->
                 state = :sys.get_state(Importer)
                 is_nil(state.timer_ref)
               end)
      end)
    end
  end

  describe "PubSub broadcasts" do
    test "imports trigger PubSub broadcasts for content reloads" do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:reload")

      log =
        capture_log(fn ->
          {:ok, posts} = Post.import()

          refute Enum.empty?(posts)

          for post <- posts do
            assert_received {:content_reload, Post, post_id}
            assert post_id == post.id
          end
        end)

      assert log == ""
    end
  end
end
