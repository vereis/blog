defmodule Blog.Content.ImporterTest do
  use Blog.DataCase, async: false

  import ExUnit.CaptureLog

  alias Blog.Content
  alias Blog.Content.Importer
  alias Blog.Posts.Post
  alias Blog.Projects.Project

  describe "content_path/0" do
    test "returns path to priv/content" do
      path = Content.content_path()
      assert path =~ "priv/content"
    end
  end

  describe "import_all/1" do
    test "imports all content types and logs errors for invalid assets" do
      path = test_content_path()

      log =
        capture_log(fn ->
          assert {:ok, %{assets: assets, posts: posts, projects: projects}} =
                   Content.import_all(path)

          refute Enum.empty?(assets)
          refute Enum.empty?(posts)
          refute Enum.empty?(projects)
        end)

      assert log =~ "Invalid imports detected for Blog.Assets.Asset"
      assert log =~ "Asset type handling not implemented"
      assert log =~ "Failed to load image"
    end

    test "broadcasts :content_imported on completion" do
      path = test_content_path()
      Phoenix.PubSub.subscribe(Blog.PubSub, Content.pubsub_topic())

      capture_log(fn ->
        {:ok, _} = Content.import_all(path)
      end)

      assert_received {:content_imported}
    end
  end

  describe "import_content/2" do
    test "imports posts from archived directory" do
      path = Path.join(test_content_path(), "archived")

      {:ok, posts} = Content.import_content(Post, path)

      refute Enum.empty?(posts)
      assert Enum.all?(posts, &is_struct(&1, Post))
    end

    test "imports assets from assets directory" do
      path = Path.join(test_content_path(), "assets")

      log =
        capture_log(fn ->
          {:ok, assets} = Content.import_content(Blog.Assets.Asset, path)
          refute Enum.empty?(assets)
        end)

      assert log =~ "Invalid imports detected"
    end

    test "imports projects from projects directory" do
      path = Path.join(test_content_path(), "projects")

      {:ok, projects} = Content.import_content(Project, path)

      refute Enum.empty?(projects)
      assert Enum.all?(projects, &is_struct(&1, Project))
    end
  end

  describe "Importer GenServer" do
    setup do
      start_supervised!(Importer)
      :ok
    end

    test "does not start filesystem watcher in test environment" do
      state = :sys.get_state(Importer)
      assert is_nil(state.watcher_pid)
    end

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

    test "debounces rapid file changes" do
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

  defp test_content_path do
    Path.join([File.cwd!(), "test/fixtures/priv/content"])
  end
end
