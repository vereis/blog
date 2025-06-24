defmodule Mix.Tasks.Blog.Gen.Post do
  @shortdoc "Generates a new blog post"

  @moduledoc """
  Generates a new blog post.

  ## Usage

      mix blog.gen.post "My New Post"
      mix blog.gen.post "My New Post" --draft
      mix blog.gen.post "My New Post" --tags="elixir,phoenix"

  ## Options

    * `--draft` - Mark the post as a draft (default: true)
    * `--tags` - Comma-separated list of tags for the post
    * `--reading-time` - Estimated reading time in minutes (auto-calculated if not provided)

  The task will:
  1. Generate a timestamped filename in the format `YYYYMMDDHHMMSS_slug.md`
  2. Create the markdown file in `priv/posts/`
  3. Generate a slug from the title
  4. Include front matter with title, slug, draft status, and other metadata
  """

  use Mix.Task

  alias Blog.Resource.Post

  @impl Mix.Task
  def run(args) do
    {opts, positional_args, _invalid} =
      OptionParser.parse(args,
        switches: [
          draft: :boolean,
          tags: :string,
          reading_time: :integer
        ],
        aliases: [
          d: :draft,
          t: :tags,
          r: :reading_time
        ]
      )

    title =
      case positional_args do
        [title | _rest] -> title
        [] -> nil
      end

    if is_nil(title) or String.trim(title) == "" do
      Mix.shell().error("Title is required. Usage: mix blog.gen.post \"My Post Title\"")
      System.halt(1)
    end

    timestamp = generate_timestamp()
    slug = generate_slug(title)
    filename = "#{timestamp}_#{slug}.md"

    # Use the same directory resolution as Blog.Resource.Post
    posts_dir = Post.source()
    file_path = Path.join([posts_dir, filename])

    tags = parse_tags(opts[:tags])
    is_draft = Keyword.get(opts, :draft, true)
    reading_time = opts[:reading_time]

    content = generate_post_content(title, slug, is_draft, tags, reading_time)

    # Ensure the directory exists
    File.mkdir_p!(posts_dir)

    case File.write(file_path, content) do
      :ok ->
        Mix.shell().info("Created blog post: #{file_path}")

      {:error, reason} ->
        Mix.shell().error("Failed to create blog post: #{reason}")
        System.halt(1)
    end
  end

  defp generate_timestamp do
    DateTime.utc_now()
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.replace(~r/[^\d]/, "")
    |> String.slice(0, 14)
  end

  defp generate_slug(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^\w\s]/, "")
    |> String.replace(~r/\s+/, "_")
    |> String.trim("_")
  end

  defp parse_tags(nil), do: []
  defp parse_tags(""), do: []

  defp parse_tags(tags_string) do
    tags_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp generate_post_content(title, slug, is_draft, tags, reading_time) do
    published_at = DateTime.to_string(DateTime.utc_now())

    reading_time_line =
      case reading_time do
        nil -> "reading_time_minutes:"
        time -> "reading_time_minutes: #{time}"
      end

    tags_section =
      case tags do
        [] ->
          "tags:"

        tag_list ->
          tags_yaml =
            Enum.map_join(tag_list, "\n", &"  - #{&1}")

          "tags:\n#{tags_yaml}"
      end

    """
    ---
    title: #{title}
    slug: #{slug}
    is_draft: #{is_draft}
    is_redacted: false
    #{reading_time_line}
    published_at: #{published_at}
    #{tags_section}
    ---

    Write your blog post content here...

    ## Introduction

    Your introduction goes here.

    ## Main Content

    Your main content goes here.

    ## Conclusion

    Your conclusion goes here.
    """
  end
end
