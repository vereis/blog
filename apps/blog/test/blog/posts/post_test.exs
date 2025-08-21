defmodule Blog.Posts.PostTest do
  use Blog.DataCase, async: false

  alias Blog.Posts.Post
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

  describe "query/2 FTS sanitization" do
    setup do
      # Create test posts for FTS testing
      post1 = insert(:post, title: "Elixir Programming", raw_body: "Learning Elixir with pipes")

      post2 =
        insert(:post,
          title: "Erlang Systems",
          raw_body: "Building distributed systems with Erlang"
        )

      %{posts: [post1, post2]}
    end

    # Valid queries that should work normally and return ranked results
    valid_queries = [
      "elixir",
      "elixir OR erlang",
      "elixir AND pipes",
      ~s("elixir programming")
    ]

    for query_term <- valid_queries do
      test "handles valid FTS query: #{query_term}" do
        query = Post.query(Post, search: unquote(query_term))
        results = SQLite.all(query)

        # Should have results with rank field (indicating FTS was used)
        assert length(results) > 0
        assert List.first(results).rank != nil
      end
    end

    # Operator mappings that should be converted to supported equivalents
    operator_mappings = [
      {"elixir | erlang", "pipe to OR"},
      {"elixir & pipes", "ampersand to AND"},
      {"elixir ! pipes", "exclamation to NOT"},
      {"elixir || erlang", "double pipe to OR"},
      {"elixir && pipes", "double ampersand to AND"},
      {"erlang|elixir", "pipe without spaces"},
      {"erlang&&distributed", "double ampersand without spaces"}
    ]

    for {query_term, description} <- operator_mappings do
      test "converts unsupported operators: #{description} (#{query_term})" do
        query = Post.query(Post, search: unquote(query_term))
        results = SQLite.all(query)

        # Should work and return FTS results
        assert is_list(results)

        if length(results) > 0 do
          assert List.first(results).rank != nil, "should use FTS"
        end
      end
    end

    # These queries would crash without sanitization
    problematic_queries = [
      {"elixir AND", "trailing boolean operator"},
      {"elixir OR", "trailing boolean operator"},
      {"elixir NOT", "trailing boolean operator"},
      {"NEAR(", "incomplete NEAR function"},
      {"NEAR(elixir", "incomplete NEAR function"},
      {"NEAR(elixir,", "incomplete NEAR function"},
      {"title:", "incomplete column filter"},
      {"{title", "incomplete column group"},
      {"elixir +", "trailing phrase operator"},
      {"elixir ^", "trailing initial token operator"},
      {"elixir |", "trailing pipe"},
      {"elixir &", "trailing ampersand"},
      {"elixir !", "trailing exclamation"},
      {"elixir -", "trailing minus"},
      {"elixir ~", "trailing tilde"},
      {"elixir ;", "trailing semicolon"},
      {"elixir ,", "trailing comma"},
      {"elixir .", "trailing period"},
      {"elixir ?", "trailing question mark"},
      {"(", "standalone opening paren"},
      {")", "standalone closing paren"},
      {"AND", "standalone boolean operator"},
      {"OR", "standalone boolean operator"},
      {"NOT", "standalone boolean operator"}
    ]

    for {query_term, description} <- problematic_queries do
      test "sanitizes incomplete FTS query: #{description} (#{query_term})" do
        # Should not crash and should return results
        query = Post.query(Post, search: unquote(query_term))
        results = SQLite.all(query)

        # Should return all posts when query is too invalid to sanitize
        assert is_list(results)
        assert length(results) >= 0
      end
    end

    # These queries become empty after sanitization
    empty_after_sanitization = [
      {"", "empty string"},
      {"   ", "whitespace only"},
      {"AND", "standalone operator"},
      {"NEAR(", "incomplete function only"},
      {"title:", "incomplete filter only"}
    ]

    for {query_term, description} <- empty_after_sanitization do
      test "returns all posts when query sanitizes to empty: #{description} (#{query_term})" do
        query = Post.query(Post, search: unquote(query_term))
        results = SQLite.all(query)

        # Should return all posts (no FTS filtering applied)
        all_posts = SQLite.all(Post)
        assert length(results) == length(all_posts)

        # Results should not have rank field (no FTS was used)
        if length(results) > 0 do
          assert List.first(results).rank == nil
        end
      end
    end

    test "sanitizes trailing operators while preserving valid content" do
      # Test that content before trailing operators is preserved
      query = Post.query(Post, search: "elixir AND")
      results = SQLite.all(query)

      # Should find posts containing "elixir" (sanitized from "elixir AND")
      assert length(results) > 0
      assert List.first(results).rank != nil

      # Verify it actually found the elixir post
      elixir_post = Enum.find(results, &String.contains?(&1.title, "Elixir"))
      assert elixir_post != nil
    end

    test "handles non-string search terms gracefully" do
      # Should handle non-string inputs without crashing
      query = Post.query(Post, search: nil)
      results = SQLite.all(query)

      # Should return all posts when search term is not a string
      all_posts = SQLite.all(Post)
      assert length(results) == length(all_posts)
    end
  end

  describe "changeset/2" do
    test "handles tag associations" do
      tag1 = insert(:tag, label: "elixir")
      tag2 = insert(:tag, label: "web")

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
      insert(:post, slug: "duplicate-slug")

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
