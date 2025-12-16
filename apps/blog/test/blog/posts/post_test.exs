defmodule Blog.Posts.PostTest do
  use Blog.DataCase, async: false

  alias Blog.Assets
  alias Blog.Posts.Post
  alias Ecto.Changeset

  @test_image_path Path.join([
                     File.cwd!(),
                     "test/fixtures/priv/assets/test_image.jpg"
                   ])

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

    test "wraps images in clickable links" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          raw_body: "![Alt text](/images/test.png)",
          slug: "test-post"
        })

      assert changeset.valid?
      assert {:ok, body} = Changeset.fetch_change(changeset, :body)

      assert body =~ ~r/<a[^>]*href="\/images\/test\.png"[^>]*>/
      assert body =~ ~r/title="View full size"/
      assert body =~ ~r/target="_blank"/
      assert body =~ ~r/rel="noopener"/
      assert body =~ ~r/<img[^>]*src="\/images\/test\.png"[^>]*>/
      assert body =~ ~r/alt="Alt text"/
    end

    test "rewrites asset paths and injects LQIP hashes" do
      {:ok, asset} = Assets.create_asset(%{path: @test_image_path})

      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          raw_body: "![Test image](#{@test_image_path})",
          slug: "test-post"
        })

      assert changeset.valid?
      assert {:ok, body} = Changeset.fetch_change(changeset, :body)

      assert body =~ ~r/<img[^>]*src="\/assets\/images\/#{asset.name}"[^>]*>/
      assert body =~ ~r/style="--lqip:#{asset.lqip_hash}"/
      assert body =~ ~r/<a[^>]*href="\/assets\/images\/#{asset.name}"[^>]*>/
      assert body =~ ~r/title="View full size"/
      assert body =~ ~r/alt="Test image"/
    end

    test "handles missing assets gracefully" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          raw_body: "![Missing](../assets/nonexistent.jpg)",
          slug: "test-post"
        })

      assert changeset.valid?
      assert {:ok, body} = Changeset.fetch_change(changeset, :body)

      assert body =~ ~r/<img[^>]*src="\.\.\/assets\/nonexistent\.jpg"[^>]*>/
      refute body =~ ~r/--lqip:/
    end

    test "skips external image URLs" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          raw_body: "![External](https://example.com/image.jpg)",
          slug: "test-post"
        })

      assert changeset.valid?
      assert {:ok, body} = Changeset.fetch_change(changeset, :body)

      assert body =~ ~r/<img[^>]*src="https:\/\/example\.com\/image\.jpg"[^>]*>/
      refute body =~ ~r/--lqip:/
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
      assert length(heading_changesets) == 7

      headings = Enum.map(heading_changesets, & &1.changes)
      assert [h0, h1, h2, h3, h4, h5, h6] = headings

      assert h0.level == 1
      assert h0.title == "Test Post"
      assert h0.link == "test-post"

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
      assert [title_heading, content_heading] = heading_changesets

      # Title heading
      assert title_heading.changes.level == 1
      assert title_heading.changes.title == "Test Post"
      assert title_heading.changes.link == "test-post"

      # Content heading
      assert content_heading.changes.link == "hello-world-this-is-a-test"
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

  describe "changeset/2 - excerpt generation" do
    test "generates excerpt from first 3 paragraphs" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          slug: "test-post",
          raw_body: """
          First paragraph.

          Second paragraph.

          Third paragraph.

          Fourth paragraph.
          """
        })

      assert changeset.valid?
      assert {:ok, excerpt} = Changeset.fetch_change(changeset, :excerpt)
      assert excerpt =~ "First paragraph"
      assert excerpt =~ "Second paragraph"
      assert excerpt =~ "Third paragraph"
      refute excerpt =~ "Fourth paragraph"
    end

    test "stops excerpt at h2 heading" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          slug: "test-post",
          raw_body: """
          First paragraph.

          Second paragraph.

          ## Heading

          Should not be in excerpt.
          """
        })

      assert changeset.valid?
      assert {:ok, excerpt} = Changeset.fetch_change(changeset, :excerpt)
      assert excerpt =~ "First paragraph"
      assert excerpt =~ "Second paragraph"
      refute excerpt =~ "Should not be in excerpt"
    end

    test "stops excerpt at list" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          slug: "test-post",
          raw_body: """
          First paragraph.

          - List item
          - Another item

          After list.
          """
        })

      assert changeset.valid?
      assert {:ok, excerpt} = Changeset.fetch_change(changeset, :excerpt)
      assert excerpt =~ "First paragraph"
      refute excerpt =~ "List item"
      refute excerpt =~ "After list"
    end

    test "handles short posts gracefully" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          slug: "test-post",
          raw_body: "Just one paragraph."
        })

      assert changeset.valid?
      assert {:ok, excerpt} = Changeset.fetch_change(changeset, :excerpt)
      assert excerpt =~ "Just one paragraph"
    end

    test "skips h1 title in excerpt" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "Test Post",
          slug: "test-post",
          raw_body: """
          # Title

          First paragraph after title.

          Second paragraph.
          """
        })

      assert changeset.valid?
      assert {:ok, excerpt} = Changeset.fetch_change(changeset, :excerpt)
      assert excerpt =~ "First paragraph after title"
      assert excerpt =~ "Second paragraph"
    end
  end

  describe "import/0" do
    test "imports posts from markdown files and inserts into database" do
      assert {:ok, imported} = Post.import()

      assert length(imported) == 3

      # Verify posts are in the database
      assert Repo.aggregate(Post, :count) == 3

      # Check published post
      published = Post |> Repo.get_by!(slug: "published-post") |> Repo.preload(:tags)
      assert published.title == "Published Test Post"
      assert published.is_draft == false
      assert published.published_at == ~U[2024-12-01 10:00:00Z]
      assert published.body =~ "<h1"
      assert published.reading_time_minutes == 1
      assert length(published.headings) == 4

      # Check tags were imported and associated
      assert length(published.tags) == 2
      tag_labels = published.tags |> Enum.map(& &1.label) |> Enum.sort()
      assert tag_labels == ["elixir", "testing"]

      # Check draft post
      draft = Repo.get_by!(Post, slug: "draft-post")
      assert draft.title == "Draft Test Post"
      assert draft.is_draft == true
      assert is_nil(draft.published_at)
      assert draft.body =~ "Draft Post"
      assert length(draft.headings) == 3

      # Check minimal post
      minimal = Repo.get_by!(Post, slug: "minimal-post")
      assert minimal.title == "Minimal Post"
      assert minimal.is_draft == false
      assert length(minimal.headings) == 1
      assert is_nil(minimal.published_at)
      assert minimal.body =~ "Just some minimal content"
    end

    test "uses custom description from YAML if provided" do
      resource = %Blog.Resource{
        path: "custom-description-post.md",
        content: """
        ---
        title: Custom Description Post
        slug: custom-description-post
        description: This is a **custom** description from YAML
        ---

        # Introduction

        This is the first paragraph of the post.

        This is the second paragraph.

        This is the third paragraph.
        """
      }

      attrs = Post.handle_import(resource)
      assert {:ok, post} = Blog.Posts.create_post(attrs)

      # Should have the custom description rendered as markdown
      assert post.description =~ "<strong>custom</strong>"
      # Excerpt should still be auto-generated from body
      assert post.excerpt =~ "first paragraph"
    end

    test "description is nil when empty string provided" do
      resource = %Blog.Resource{
        path: "empty-description-post.md",
        content: """
        ---
        title: Empty Description Post
        slug: empty-description-post
        description: ""
        ---

        # Introduction

        This is the first paragraph of the post.

        This is the second paragraph.
        """
      }

      attrs = Post.handle_import(resource)
      assert {:ok, post} = Blog.Posts.create_post(attrs)

      # Description should be nil when empty
      assert is_nil(post.description)
      # Excerpt should still be auto-generated
      assert post.excerpt =~ "first paragraph"
    end

    test "description is nil when not provided" do
      resource = %Blog.Resource{
        path: "no-description-post.md",
        content: """
        ---
        title: No Description Post
        slug: no-description-post
        ---

        # Introduction

        This is the first paragraph of the post.

        This is the second paragraph.
        """
      }

      attrs = Post.handle_import(resource)
      assert {:ok, post} = Blog.Posts.create_post(attrs)

      # Description should be nil when not provided
      assert is_nil(post.description)
      # Excerpt should still be auto-generated
      assert post.excerpt =~ "first paragraph"
    end
  end
end
