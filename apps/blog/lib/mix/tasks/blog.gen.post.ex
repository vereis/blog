defmodule Mix.Tasks.Blog.Gen.Post do
  @shortdoc "Generates a new blog post markdown file"

  @moduledoc """
  Generates a new blog post markdown file with YAML frontmatter.

  ## Usage

      mix blog.gen.post "My Post Title"
      mix blog.gen.post "My Post Title" --slug custom-slug
      mix blog.gen.post "My Post Title" --publish

  ## Options

    * `--slug` - Custom slug (default: generated from title)
    * `--publish` - Mark as published and set published_at to now (default: draft)

  ## Examples

      # Generate a draft post
      mix blog.gen.post "Getting Started with Elixir"

      # Generate a published post
      mix blog.gen.post "My New Tutorial" --publish

      # Generate with custom slug
      mix blog.gen.post "Hello World" --slug my-custom-slug

  """

  use Mix.Task

  alias Blog.Posts.Post

  @impl Mix.Task
  def run(args) do
    {opts, rest, _} =
      OptionParser.parse(args,
        switches: [publish: :boolean, slug: :string],
        aliases: [p: :publish, s: :slug]
      )

    case rest do
      [title | _] ->
        generate_post(title, opts)

      [] ->
        Mix.raise("""
        Expected a post title as argument.

        Usage:
            mix blog.gen.post "My Post Title"
        """)
    end
  end

  defp generate_post(title, opts) do
    slug = opts[:slug] || Post.slugify(title)
    is_draft = !opts[:publish]
    published_at = if opts[:publish], do: DateTime.utc_now()

    content = build_post_content(title, slug, is_draft, published_at)

    posts_dir = Path.join([File.cwd!(), "apps/blog/priv/posts"])
    File.mkdir_p!(posts_dir)

    timestamp = Calendar.strftime(DateTime.utc_now(), "%Y%m%d%H%M%S")
    filename_slug = Post.slugify(title, separator: "_")
    filename = "#{timestamp}_#{filename_slug}.md"
    filepath = Path.join(posts_dir, filename)

    File.write!(filepath, content)

    Mix.shell().info("Generated blog post: #{filepath}")
  end

  defp build_post_content(title, slug, is_draft, published_at) do
    published_at_line =
      if published_at do
        "published_at: \"#{DateTime.to_iso8601(published_at)}\"\n"
      else
        ""
      end

    """
    ---
    title: "#{title}"
    slug: "#{slug}"
    is_draft: #{is_draft}
    #{published_at_line}---

    # #{title}

    Write your post content here...
    """
  end
end
