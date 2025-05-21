defmodule Blog.Posts do
  @moduledoc "Context module exposing an API for managing Posts and related data."

  alias Blog.Posts.Image
  alias Blog.Posts.Post
  alias Blog.Posts.Tag
  alias Blog.Repo

  @spec source_path() :: Path.t()
  def source_path do
    :dev = apply(Mix, :env, [])
    "apps/blog/priv/posts"
  rescue
    _e ->
      :blog
      |> :code.priv_dir()
      |> Path.join("posts")
  end

  @spec image_path() :: Path.t()
  def image_path do
    :dev = apply(Mix, :env, [])
    "apps/blog/priv/images"
  rescue
    _e ->
      :blog
      |> :code.priv_dir()
      |> Path.join("images")
  end

  @spec upsert_image(attrs :: map()) :: {:ok, Image.t()} | {:error, Ecto.Changeset.t()}
  def upsert_image(attrs) do
    (get_image(name: attrs.name) || %Image{})
    |> Image.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @spec get_image(id :: integer()) :: Image.t() | nil
  @spec get_image(filters :: Keyword.t()) :: Image.t() | nil
  def get_image(image_id) when is_integer(image_id) do
    get_image(id: image_id)
  end

  def get_image(filters) do
    filters
    |> Image.query()
    |> Repo.one()
  end

  @spec list_images(filters :: Keyword.t()) :: [Image.t()]
  def list_images(filters \\ []) do
    filters
    |> Image.query()
    |> Repo.all()
  end

  @spec upsert_post(attrs :: map()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def upsert_post(attrs) do
    (get_post(slug: attrs.slug) || %Post{})
    |> Post.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @spec get_post(id :: integer()) :: Post.t() | nil
  @spec get_post(filters :: Keyword.t()) :: Post.t() | nil
  def get_post(post_id) when is_integer(post_id) do
    get_post(id: post_id)
  end

  def get_post(filters) do
    filters
    |> Post.query()
    |> Repo.one()
    |> Repo.preload(:tags)
  end

  @spec list_posts(filters :: Keyword.t()) :: [Post.t()]
  def list_posts(filters \\ []) do
    filters
    |> Keyword.put(:is_redacted, false)
    |> Post.query()
    |> Repo.all()
    |> Repo.preload(:tags)
  end

  @spec get_tag(id :: integer()) :: Tag.t() | nil
  @spec get_tag(filters :: Keyword.t()) :: Tag.t() | nil
  def get_tag(tag_id) when is_integer(tag_id) do
    get_tag(id: tag_id)
  end

  def get_tag(filters) do
    filters
    |> Tag.query()
    |> Repo.one()
  end

  @spec list_tags(filters :: Keyword.t()) :: [Tag.t()]
  def list_tags(filters \\ []) do
    filters
    |> Tag.query()
    |> Repo.all()
  end
end
