defmodule Blog.Posts do
  @moduledoc "Context module for managing blog posts and tags."

  alias Blog.Posts.Post
  alias Blog.Posts.Tag
  alias Blog.Repo.SQLite

  require Logger

  @doc """
  Gets a single post by ID or filters.
  """
  @spec get_post(id :: integer()) :: Post.t() | nil
  @spec get_post(filters :: Keyword.t()) :: Post.t() | nil
  def get_post(post_id) when is_integer(post_id) do
    get_post(id: post_id)
  end

  def get_post(filters) do
    filters
    |> Keyword.put_new(:limit, 1)
    |> Post.query()
    |> SQLite.one()
    |> SQLite.preload(:tags)
  rescue
    exception ->
      if fts_error?(exception) do
        Logger.warning("FTS query error in get_post/1", error: Exception.message(exception))
        nil
      else
        reraise(exception, __STACKTRACE__)
      end
  end

  @doc """
  Lists posts with optional filters.
  """
  @spec list_posts(filters :: Keyword.t()) :: [Post.t()]
  def list_posts(filters \\ []) do
    filters
    |> Keyword.put(:is_redacted, false)
    |> Post.query()
    |> SQLite.all()
    |> SQLite.preload(:tags)
  rescue
    exception ->
      if fts_error?(exception) do
        Logger.warning("FTS query error in list_posts/1", error: Exception.message(exception))
        []
      else
        reraise(exception, __STACKTRACE__)
      end
  end

  @doc """
  Creates or updates a post with the given attributes.
  """
  @spec upsert_post(attrs :: map()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def upsert_post(attrs) do
    (get_post(slug: attrs.slug) || %Post{})
    |> Post.changeset(attrs)
    |> SQLite.insert_or_update()
  end

  @doc """
  Gets a single tag by ID or filters.
  """
  @spec get_tag(id :: integer()) :: Tag.t() | nil
  @spec get_tag(filters :: Keyword.t()) :: Tag.t() | nil
  def get_tag(tag_id) when is_integer(tag_id) do
    get_tag(id: tag_id)
  end

  def get_tag(filters) do
    filters
    |> Tag.query()
    |> SQLite.one()
  end

  @doc """
  Lists tags with optional filters.
  """
  @spec list_tags(filters :: Keyword.t()) :: [Tag.t()]
  def list_tags(filters \\ []) do
    filters
    |> Tag.query()
    |> SQLite.all()
  end

  @doc """
  Creates or updates a tag with the given attributes.
  """
  @spec upsert_tag(attrs :: map()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def upsert_tag(attrs) do
    (get_tag(label: Map.get(attrs, :label, "N/A")) || %Tag{})
    |> Tag.changeset(attrs)
    |> SQLite.insert_or_update()
  end

  # Check if an exception is related to FTS queries
  defp fts_error?(%Exqlite.Error{statement: statement}) when is_binary(statement) do
    String.contains?(statement, "posts_fts") and String.contains?(statement, "MATCH")
  end

  defp fts_error?(_exception), do: false
end
