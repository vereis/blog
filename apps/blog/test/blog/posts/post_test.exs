defmodule Blog.Posts.PostTest do
  use Blog.DataCase, async: false

  alias Blog.Posts.Post
  alias Ecto.Changeset

  describe "changeset/2 - validation" do
    test "validates required fields" do
      changeset = Post.changeset(%Post{}, %{})

      refute changeset.valid?
      assert %{title: ["can't be blank"]} = errors_on(changeset)
      assert %{raw_body: ["can't be blank"]} = errors_on(changeset)
      assert %{slug: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts lowercase slug" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test",
          raw_body: "# Test",
          slug: "lowercase"
        })

      assert changeset.valid?
    end

    test "accepts slug with hyphens" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test",
          raw_body: "# Test",
          slug: "with-hyphens"
        })

      assert changeset.valid?
    end

    test "accepts slug with underscores" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test",
          raw_body: "# Test",
          slug: "with_underscores"
        })

      assert changeset.valid?
    end

    test "accepts slug with numbers" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test",
          raw_body: "# Test",
          slug: "numbers123"
        })

      assert changeset.valid?
    end

    test "rejects slug with uppercase letters" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test",
          raw_body: "# Test",
          slug: "UPPERCASE"
        })

      refute changeset.valid?
      assert %{slug: [_error]} = errors_on(changeset)
    end

    test "rejects slug with spaces" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test",
          raw_body: "# Test",
          slug: "has spaces"
        })

      refute changeset.valid?
      assert %{slug: [_error]} = errors_on(changeset)
    end

    test "rejects slug with special characters" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test",
          raw_body: "# Test",
          slug: "has@special!chars"
        })

      refute changeset.valid?
      assert %{slug: [_error]} = errors_on(changeset)
    end

    test "rejects slug with dots" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test",
          raw_body: "# Test",
          slug: "has.dots"
        })

      refute changeset.valid?
      assert %{slug: [_error]} = errors_on(changeset)
    end
  end

  describe "changeset/2 - markdown processing" do
    test "processes markdown and generates HTML" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          raw_body: "# Hello World\n\nThis is a test.",
          slug: "test-post"
        })

      assert changeset.valid?
      assert {:ok, body} = Changeset.fetch_change(changeset, :body)
      assert body =~ "<h1"
      assert body =~ "Hello World"
      assert body =~ "<p>"
      assert body =~ "This is a test."
    end

    test "does not process markdown if changeset is invalid" do
      changeset =
        Post.changeset(%Post{}, %{
          raw_body: "# Test"
        })

      refute changeset.valid?
    end
  end

  describe "changeset/2 - heading extraction" do
    test "extracts all heading levels (h1-h6)" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          raw_body: """
          # Heading One
          ## Heading Two
          ### Heading Three
          #### Heading Four
          ##### Heading Five
          ###### Heading Six
          """,
          slug: "test-post"
        })

      assert changeset.valid?
      assert {:ok, heading_changesets} = Changeset.fetch_change(changeset, :headings)
      assert length(heading_changesets) == 6

      headings = Enum.map(heading_changesets, & &1.changes)
      assert [h1, h2, h3, h4, h5, h6] = headings

      assert h1.level == 1
      assert h1.title == "Heading One"
      assert h1.link == "heading-one"

      assert h2.level == 2
      assert h2.title == "Heading Two"
      assert h2.link == "heading-two"

      assert h3.level == 3
      assert h3.title == "Heading Three"
      assert h3.link == "heading-three"

      assert h4.level == 4
      assert h4.title == "Heading Four"
      assert h4.link == "heading-four"

      assert h5.level == 5
      assert h5.title == "Heading Five"
      assert h5.link == "heading-five"

      assert h6.level == 6
      assert h6.title == "Heading Six"
      assert h6.link == "heading-six"
    end

    test "injects unique IDs into multiple heading HTML elements" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          raw_body: """
          # First Heading

          - Item 1
          - Item 2

          ## Second Heading
          ### Third Heading
          """,
          slug: "test-post"
        })

      assert changeset.valid?
      assert {:ok, body} = Changeset.fetch_change(changeset, :body)
      assert body =~ ~r/id="first-heading"/
      assert body =~ ~r/id="second-heading"/
      assert body =~ ~r/id="third-heading"/
    end

    test "slugifies heading titles correctly" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          raw_body: "# Hello World! This is a Test",
          slug: "test-post"
        })

      assert changeset.valid?
      assert {:ok, heading_changesets} = Changeset.fetch_change(changeset, :headings)
      assert [heading_changeset] = heading_changesets
      heading = heading_changeset.changes
      assert heading.link == "hello-world-this-is-a-test"
    end
  end

  describe "changeset/2 - reading time calculation" do
    test "rounds up reading time to minimum 1 minute" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          raw_body: "Short post",
          slug: "test-post"
        })

      assert changeset.valid?
      assert {:ok, 1} = Changeset.fetch_change(changeset, :reading_time_minutes)
    end

    test "calculates reading time for 520 words as 2 minutes" do
      words = String.duplicate("word ", 520)

      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          raw_body: words,
          slug: "test-post"
        })

      assert changeset.valid?
      assert {:ok, 2} = Changeset.fetch_change(changeset, :reading_time_minutes)
    end
  end

  describe "import/0" do
    test "imports posts from markdown files and inserts into database" do
      assert {:ok, imported} = Post.import()

      assert length(imported) == 3

      # Verify posts are in the database
      assert Repo.aggregate(Post, :count) == 3

      # Check published post
      published = Repo.get_by!(Post, slug: "published-post")
      assert published.title == "Published Test Post"
      assert published.is_draft == false
      assert published.published_at == ~U[2024-12-01 10:00:00Z]
      assert published.body =~ "<h1"
      assert published.reading_time_minutes == 1
      assert length(published.headings) == 3

      # Check draft post
      draft = Repo.get_by!(Post, slug: "draft-post")
      assert draft.title == "Draft Test Post"
      assert draft.is_draft == true
      assert is_nil(draft.published_at)
      assert draft.body =~ "Draft Post"
      assert length(draft.headings) == 2

      # Check minimal post
      minimal = Repo.get_by!(Post, slug: "minimal-post")
      assert minimal.title == "Minimal Post"
      assert minimal.is_draft == false
      assert is_nil(minimal.published_at)
      assert minimal.body =~ "Just some minimal content"
    end
  end
end
