defmodule Blog.Posts.Importer do
  @moduledoc """
  Responsible for importing, creating or upserting, posts when run via the `run!/0`
  function.

  Parses all posts in the configured directory, imports any tags specified, and
  upserts all posts as configured.

  See `Blog.Posts` and nested schema modules for more information on the data model.
  """

  alias Blog.Posts
  alias Blog.Posts.Post
  alias Blog.Posts.Tag
  alias Blog.Repo

  require Logger

  @spec run!() :: :ok
  def run! do
    now =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)

    image_attrs =
      Posts.image_path()
      |> File.ls!()
      |> Task.async_stream(&parse_images/1)
      |> Stream.map(fn {:ok, attrs} -> attrs end)
      |> Enum.with_index(1)
      |> Enum.map(fn {attrs, index} -> Map.put(attrs, :id, index) end)

    post_attrs =
      Posts.source_path()
      |> File.ls!()
      |> Task.async_stream(&parse_posts/1)
      |> Stream.map(fn {:ok, attrs} -> attrs end)
      |> Enum.sort_by(& &1.sort_key, &<=/2)
      |> Enum.with_index(1)
      |> Enum.map(fn {attrs, index} -> Map.put(attrs, :id, index) end)

    {_count, tags} =
      post_attrs
      |> Enum.flat_map(& &1.tags)
      |> Enum.uniq()
      |> Enum.map(&%{label: &1, inserted_at: now, updated_at: now})
      |> then(
        &Repo.insert_all(
          Tag,
          &1,
          on_conflict: {:replace_all_except, [:id, :inserted_at, :updated_at]},
          returning: true
        )
      )

    tag_lookup_table = Map.new(tags, fn tag -> {tag.label, tag.id} end)

    post_attrs
    |> Stream.map(fn x -> Map.put(x, :tag_ids, Enum.map(x.tags, &tag_lookup_table[&1])) end)
    |> Task.async_stream(&({:ok, %Post{}} = Posts.upsert_post(&1)), max_concurrency: 1)
    |> Stream.run()

    image_attrs
    |> Task.async_stream(&({:ok, %Posts.Image{}} = Posts.upsert_image(&1)), max_concurrency: 1)
    |> Stream.run()
  after
    Phoenix.PubSub.broadcast(Blog.PubSub, "post:reload", :post_reload)
  end

  defp parse_images(filename) do
    image_path = Path.join(Posts.image_path(), filename)
    %{path: image_path}
  end

  defp parse_posts(filename) do
    [metadata_yaml, raw_body] =
      Posts.source_path()
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
end
