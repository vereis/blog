defmodule Blog.Posts.PostTest do
  use Blog.DataCase, async: true

  alias Blog.Posts.Post
  alias Blog.Posts.Tag
  alias Blog.Repo.SQLite

  describe "generate_reading_time/2" do
    test "generates reading time when not provided" do
      # Create content with ~260 words (should be 1 minute)
      words = String.duplicate("word ", 260)

      attrs = %{
        title: "Test Post",
        slug: "test-post",
        raw_body: words
      }

      changeset = Post.changeset(%Post{}, attrs)
      assert changeset.changes.reading_time_minutes == 1
    end

    test "uses provided reading time when given" do
      attrs = %{
        title: "Test Post",
        slug: "test-post",
        raw_body: "Short content",
        reading_time_minutes: 5
      }

      changeset = Post.changeset(%Post{}, attrs)
      assert changeset.changes.reading_time_minutes == 5
    end
  end

  describe "generate_headings/1" do
    test "generates headings with IDs and links" do
      attrs = %{
        title: "Main Title",
        slug: "test-post",
        raw_body: """
        # First Heading

        Some content.

        ## Second Heading

        More content.

        ### Third Heading

        Even more content.
        """
      }

      changeset = Post.changeset(%Post{}, attrs)
      headings = changeset.changes.headings

      # Should include the post title as level 1 heading
      assert length(headings) == 4

      # Check main title (from post title)
      main_heading =
        Enum.find(
          headings,
          &(&1.changes.level == 1 && String.contains?(&1.changes.title, "Main Title"))
        )

      assert main_heading != nil
      assert main_heading.changes.link == "#heading-main-title"

      # Check generated headings from markdown
      first_heading = Enum.find(headings, &String.contains?(&1.changes.title, "First Heading"))
      assert first_heading != nil
      assert first_heading.changes.level == 1
      assert first_heading.changes.link == "#heading-first-heading"

      second_heading = Enum.find(headings, &String.contains?(&1.changes.title, "Second Heading"))
      assert second_heading != nil
      assert second_heading.changes.level == 2
      assert second_heading.changes.link == "#heading-second-heading"

      third_heading = Enum.find(headings, &String.contains?(&1.changes.title, "Third Heading"))
      assert third_heading != nil
      assert third_heading.changes.level == 3
      assert third_heading.changes.link == "#heading-third-heading"
    end

    test "adds heading IDs to HTML body" do
      attrs = %{
        title: "Test Post",
        slug: "test-post",
        raw_body: """
        # First Heading

        Content here.
        """
      }

      changeset = Post.changeset(%Post{}, attrs)
      assert changeset.changes.body =~ "<h1 id=\"heading-first-heading\""
    end
  end

  describe "generate_body/1" do
    test "renders markdown to HTML" do
      attrs = %{
        title: "Test Post",
        slug: "test-post",
        raw_body: """
        # Heading

        Some **bold** text and *italic* text.
        """
      }

      changeset = Post.changeset(%Post{}, attrs)
      assert changeset.changes.body =~ "<h1"
      assert changeset.changes.body =~ "<strong"
      assert changeset.changes.body =~ "<em"
    end

    test "renders internal images with correct path" do
      attrs = %{
        title: "Test Post",
        slug: "test-post",
        raw_body: """
        ![Image](../images/test.png)

        Some content.
        """
      }

      changeset = Post.changeset(%Post{}, attrs)

      assert changeset.changes.body =~ "<img src=\"\/assets\/images\/test\.png\""
      refute changeset.changes.body =~ "../images"
    end
  end

  describe "generate_description/1" do
    test "generates description from first 8 lines" do
      attrs = %{
        title: "Test Post",
        slug: "test-post",
        raw_body: """
        Line 1
        Line 2
        Line 3
        Line 4
        Line 5
        Line 6
        Line 7
        Line 8
        Line 9 should not be included
        Line 10 should not be included
        """
      }

      changeset = Post.changeset(%Post{}, attrs)

      assert changeset.changes.description =~ "Line 1"
      assert changeset.changes.description =~ "Line 8"
      refute changeset.changes.description =~ "Line 9"
      assert changeset.changes.description =~ "... Read more ..."
    end
  end

  describe "changeset/2" do
    test "handles tag associations" do
      {:ok, tag1} = SQLite.insert(%Tag{label: "elixir"})
      {:ok, tag2} = SQLite.insert(%Tag{label: "web"})

      attrs = %{
        title: "Test Post",
        slug: "test-post",
        raw_body: "Content",
        tag_ids: [tag1.id, tag2.id]
      }

      changeset = Post.changeset(%Post{}, attrs)
      assert changeset.valid?
    end

    test "enforces unique slug constraint" do
      {:ok, _existing} =
        SQLite.insert(%Post{
          title: "Existing Post",
          slug: "duplicate-slug",
          body: "Content",
          description: "Description"
        })

      attrs = %{
        title: "New Post",
        slug: "duplicate-slug",
        raw_body: "Content"
      }

      changeset = Post.changeset(%Post{}, attrs)
      assert {:error, changeset} = SQLite.insert(changeset)
      assert %{slug: ["has already been taken"]} = errors_on(changeset)
    end
  end
end
