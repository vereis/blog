defmodule Blog.Resource.Post do
  @moduledoc """
  Resource implementation for importing blog posts.

  Implements the Blog.Resource behaviour to provide post-specific
  import functionality.
  """

  @behaviour Blog.Resource

  alias Blog.Posts
  alias Blog.Posts.Post
  alias Blog.Posts.Tag
  alias Blog.Repo.SQLite

  @impl Blog.Resource
  def source do
    case Blog.env() do
      :dev ->
        "apps/blog/priv/posts"

      _other ->
        :blog
        |> :code.priv_dir()
        |> Path.join("posts")
    end
  end

  @impl Blog.Resource
  def parse(filename) do
    # NOTE: this function is unit tested, so we need to use `__MODULE__` for internal
    #       function calls to avoid mock errors.
    [metadata_yaml, raw_body] =
      __MODULE__.source()
      |> Path.join(filename)
      |> File.read!()
      |> String.split("---\n", parts: 3)
      |> tl()

    metadata = YamlElixir.read_from_string!(metadata_yaml)

    %{
      id: nil,
      is_draft: metadata["is_draft"],
      is_redacted: metadata["is_redacted"] || false,
      published_at: metadata["published_at"],
      raw_body: String.trim(raw_body),
      reading_time_minutes: metadata["reading_time_minutes"],
      slug: metadata["slug"],
      tags: metadata["tags"],
      title: metadata["title"],
      sort_key:
        metadata["published_at"]
        |> String.replace(~r/[^0-9]/, "")
        |> Integer.parse()
        |> elem(0)
    }
  end

  @impl Blog.Resource
  def import(parsed_posts) do
    now =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)

    post_attrs =
      parsed_posts
      |> Enum.sort_by(& &1.sort_key, &<=/2)
      |> Enum.with_index(1)
      |> Enum.map(fn {attrs, index} -> Map.put(attrs, :id, index) end)

    # Create tags first
    {_count, tags} =
      post_attrs
      |> Enum.flat_map(& &1.tags)
      |> Enum.uniq()
      |> Enum.map(&%{label: &1, inserted_at: now, updated_at: now})
      |> then(
        &SQLite.insert_all(
          Tag,
          &1,
          on_conflict: {:replace_all_except, [:id, :inserted_at, :updated_at]},
          returning: true
        )
      )

    tag_lookup_table = Map.new(tags, fn tag -> {tag.label, tag.id} end)

    # Import posts with tag associations and collect results
    imported_posts =
      for post <- post_attrs,
          post = Map.put(post, :tag_ids, Enum.map(post.tags, &tag_lookup_table[&1])) do
        {:ok, %Post{} = imported_post} = Posts.upsert_post(post)
        imported_post
      end

    {:ok, imported_posts}
  end
end
