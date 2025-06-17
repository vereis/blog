defmodule Blog.Resource.PostTest do
  use Blog.DataCase, async: true

  alias Blog.Posts.Post
  alias Blog.Posts.Tag
  alias Blog.Repo.SQLite
  alias Blog.Resource.Post, as: PostResource

  describe "source/0" do
    test "returns development path when in development" do
      path = PostResource.source()
      assert is_binary(path)
      assert String.ends_with?(path, "posts")
    end
  end

  describe "parse/1" do
    setup do
      {:ok, temp_dir} = Briefly.create(directory: true)
      fixture_dir = Path.join(temp_dir, "posts")
      File.mkdir_p!(fixture_dir)

      post_content = """
      ---
      title: "Test Post"
      slug: "test-post"
      is_draft: false
      is_redacted: false
      published_at: "2023-07-22T14:03:00Z"
      reading_time_minutes: 5
      tags: ["test", "elixir"]
      ---

      This is the body of the test post.

      ## A heading

      Some more content here.
      """

      File.write!("#{fixture_dir}/test_post.md", post_content)

      %{fixture_dir: fixture_dir, filename: "test_post.md"}
    end

    test "parses markdown file with YAML frontmatter correctly", %{
      fixture_dir: fixture_dir,
      filename: filename
    } do
      stub(PostResource, :source, fn -> IO.inspect(fixture_dir, label: :wow) end)
      result = PostResource.parse(filename)

      assert result.title == "Test Post"
      assert result.slug == "test-post"
      assert result.is_draft == false
      assert result.is_redacted == false
      assert result.published_at == "2023-07-22T14:03:00Z"
      assert result.reading_time_minutes == 5
      assert result.tags == ["test", "elixir"]

      assert result.raw_body ==
               "This is the body of the test post.\n\n## A heading\n\nSome more content here."

      assert result.sort_key == 20_230_722_140_300
      assert result.id == nil
    end

    test "handles missing optional fields" do
      {:ok, temp_dir} = Briefly.create(directory: true)
      fixture_dir = Path.join(temp_dir, "posts")
      File.mkdir_p!(fixture_dir)

      post_content = """
      ---
      title: "Minimal Post"
      slug: "minimal-post"
      published_at: "2023-07-22T14:03:00Z"
      tags: []
      ---

      Minimal content.
      """

      File.write!(Path.join(fixture_dir, "minimal_post.md"), post_content)

      stub(PostResource, :source, fn -> fixture_dir end)
      result = PostResource.parse("minimal_post.md")

      assert result.title == "Minimal Post"
      assert result.slug == "minimal-post"
      assert result.is_draft == nil
      # defaults to false
      assert result.is_redacted == false
      assert result.reading_time_minutes == nil
      assert result.tags == []
    end
  end

  describe "import/1" do
    test "imports posts and creates tags" do
      parsed_posts = [
        %{
          id: nil,
          title: "First Post",
          slug: "first-post",
          raw_body: "Content of first post",
          is_draft: false,
          is_redacted: false,
          published_at: "2023-07-22T14:03:00Z",
          reading_time_minutes: 3,
          tags: ["elixir", "test"],
          sort_key: 20_230_722_140_300
        },
        %{
          id: nil,
          title: "Second Post",
          slug: "second-post",
          raw_body: "Content of second post",
          is_draft: true,
          is_redacted: false,
          published_at: "2023-07-23T10:00:00Z",
          reading_time_minutes: 2,
          tags: ["elixir", "web"],
          sort_key: 20_230_723_100_000
        }
      ]

      assert {:ok, imported_posts} = PostResource.import(parsed_posts)
      assert length(imported_posts) == 2

      # Verify tags were created
      tags = SQLite.all(Tag)
      tag_labels = Enum.map(tags, & &1.label)
      assert "elixir" in tag_labels
      assert "test" in tag_labels
      assert "web" in tag_labels

      # Verify posts were created
      posts = Post |> SQLite.all() |> SQLite.preload(:tags)
      assert length(posts) == 2

      first_post = Enum.find(posts, &(&1.slug == "first-post"))
      assert first_post.title == "First Post"
      # Should be assigned index 1
      assert first_post.id == 1

      post_tag_labels = Enum.map(first_post.tags, & &1.label)
      assert "elixir" in post_tag_labels
      assert "test" in post_tag_labels

      second_post = Enum.find(posts, &(&1.slug == "second-post"))
      assert second_post.title == "Second Post"
      # Should be assigned index 2
      assert second_post.id == 2
    end

    test "handles empty list" do
      assert {:ok, []} = PostResource.import([])

      assert SQLite.all(Tag) == []
      assert SQLite.all(Post) == []
    end

    test "sorts posts by sort_key before import" do
      parsed_posts = [
        %{
          id: nil,
          title: "Later Post",
          slug: "later-post",
          raw_body: "Content",
          tags: [],
          sort_key: 20_230_723_000_000
        },
        %{
          id: nil,
          title: "Earlier Post",
          slug: "earlier-post",
          raw_body: "Content",
          tags: [],
          sort_key: 20_230_722_000_000
        }
      ]

      assert {:ok, imported_posts} = PostResource.import(parsed_posts)
      assert length(imported_posts) == 2

      posts = SQLite.all(Post)
      earlier_post = Enum.find(posts, &(&1.slug == "earlier-post"))
      later_post = Enum.find(posts, &(&1.slug == "later-post"))

      # Earlier post should get id 1, later post should get id 2
      assert earlier_post.id == 1
      assert later_post.id == 2
    end

    test "handles duplicate tags" do
      parsed_posts = [
        %{
          id: nil,
          title: "Post 1",
          slug: "post-1",
          raw_body: "Content",
          tags: ["elixir", "test"],
          sort_key: 20_230_722_000_000
        },
        %{
          id: nil,
          title: "Post 2",
          slug: "post-2",
          raw_body: "Content",
          # "elixir" appears in both
          tags: ["elixir", "web"],
          sort_key: 20_230_723_000_000
        }
      ]

      assert {:ok, imported_posts} = PostResource.import(parsed_posts)
      assert length(imported_posts) == 2

      # Should only create 3 unique tags
      tags = SQLite.all(Tag)
      assert length(tags) == 3

      tag_labels = Enum.map(tags, & &1.label)
      assert "elixir" in tag_labels
      assert "test" in tag_labels
      assert "web" in tag_labels
    end
  end
end
