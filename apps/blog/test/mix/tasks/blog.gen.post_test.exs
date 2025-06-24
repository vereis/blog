defmodule Mix.Tasks.Blog.Gen.PostTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @temp_dir "tmp/test_posts"

  setup do
    # Clean up any existing temp directory
    File.rm_rf!(@temp_dir)
    File.mkdir_p!(@temp_dir)

    on_exit(fn ->
      File.rm_rf!(@temp_dir)
    end)

    :ok
  end

  describe "run/1" do
    test "generates a blog post with basic title" do
      # Create a temporary posts directory in the actual location
      posts_dir = Blog.Resource.Post.source()
      File.mkdir_p!(posts_dir)

      output =
        capture_io(fn ->
          Mix.Tasks.Blog.Gen.Post.run(["Test Post Title"])
        end)

      assert output =~ "Created blog post:"
      assert output =~ "test_post_title.md"

      # Find the generated file
      files = posts_dir |> File.ls!() |> Enum.filter(&String.contains?(&1, "test_post_title"))
      assert length(files) == 1

      file_path = Path.join(posts_dir, hd(files))
      content = File.read!(file_path)

      # Check front matter
      assert content =~ "title: Test Post Title"
      assert content =~ "slug: test_post_title"
      assert content =~ "is_draft: true"
      assert content =~ "is_redacted: false"
      assert content =~ "reading_time_minutes:"
      assert content =~ "published_at:"
      assert content =~ "tags:"

      # Check template content
      assert content =~ "Write your blog post content here..."
      assert content =~ "## Introduction"

      # Clean up
      File.rm!(file_path)
    end

    test "generates a blog post with tags" do
      posts_dir = Blog.Resource.Post.source()
      File.mkdir_p!(posts_dir)

      output =
        capture_io(fn ->
          Mix.Tasks.Blog.Gen.Post.run(["Tagged Post", "--tags=elixir,phoenix,web"])
        end)

      assert output =~ "Created blog post:"

      files = posts_dir |> File.ls!() |> Enum.filter(&String.contains?(&1, "tagged_post"))
      file_path = Path.join(posts_dir, hd(files))
      content = File.read!(file_path)

      assert content =~ "tags:\n  - elixir\n  - phoenix\n  - web"

      File.rm!(file_path)
    end

    test "generates a blog post with reading time" do
      posts_dir = Blog.Resource.Post.source()
      File.mkdir_p!(posts_dir)

      output =
        capture_io(fn ->
          Mix.Tasks.Blog.Gen.Post.run(["Timed Post", "--reading-time=5"])
        end)

      assert output =~ "Created blog post:"

      files = posts_dir |> File.ls!() |> Enum.filter(&String.contains?(&1, "timed_post"))
      file_path = Path.join(posts_dir, hd(files))
      content = File.read!(file_path)

      assert content =~ "reading_time_minutes: 5"

      File.rm!(file_path)
    end

    test "generates a blog post with draft flag set to false" do
      posts_dir = Blog.Resource.Post.source()
      File.mkdir_p!(posts_dir)

      output =
        capture_io(fn ->
          Mix.Tasks.Blog.Gen.Post.run(["Published Post", "--draft=false"])
        end)

      assert output =~ "Created blog post:"

      files = posts_dir |> File.ls!() |> Enum.filter(&String.contains?(&1, "published_post"))
      file_path = Path.join(posts_dir, hd(files))
      content = File.read!(file_path)

      assert content =~ "is_draft: false"

      File.rm!(file_path)
    end

    test "generates filename with timestamp" do
      posts_dir = Blog.Resource.Post.source()
      File.mkdir_p!(posts_dir)

      capture_io(fn ->
        Mix.Tasks.Blog.Gen.Post.run(["Timestamped Post"])
      end)

      files = posts_dir |> File.ls!() |> Enum.filter(&String.contains?(&1, "timestamped_post"))
      filename = hd(files)

      # Should match pattern: YYYYMMDDHHMMSS_slug.md
      assert Regex.match?(~r/^\d{14}_timestamped_post\.md$/, filename)

      File.rm!(Path.join(posts_dir, filename))
    end

    test "handles special characters in title" do
      posts_dir = Blog.Resource.Post.source()
      File.mkdir_p!(posts_dir)

      capture_io(fn ->
        Mix.Tasks.Blog.Gen.Post.run(["Post with Special Characters! & Symbols?"])
      end)

      files =
        posts_dir
        |> File.ls!()
        |> Enum.filter(&String.contains?(&1, "post_with_special_characters"))

      assert length(files) == 1

      filename = hd(files)
      assert String.contains?(filename, "post_with_special_characters_symbols")

      File.rm!(Path.join(posts_dir, filename))
    end
  end
end
