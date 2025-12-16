defmodule Blog.Posts do
  @moduledoc false

  alias Blog.Posts.Post
  alias Blog.Repo

  @spec list_posts(Keyword.t()) :: [Post.t()]
  def list_posts(filters \\ []) do
    filters
    |> Keyword.put_new(:preload, :tags)
    |> Keyword.put_new(:is_draft, false)
    |> Post.query()
    |> Repo.all()
  end

  @spec get_post(integer()) :: Post.t() | nil
  @spec get_post(Keyword.t()) :: Post.t() | nil
  def get_post(post_id) when is_integer(post_id) do
    get_post(id: post_id)
  end

  def get_post(filters) when is_list(filters) do
    filters
    |> Keyword.merge(preload: :tags, limit: 1)
    |> Post.query()
    |> Repo.one()
  end

  @spec create_post(map()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t(Post.t())}
  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_post(Post.t(), map()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t(Post.t())}
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @spec upsert_post(map()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t(Post.t())}
  def upsert_post(attrs) when is_map(attrs) do
    case get_post(slug: Map.get(attrs, :slug)) do
      nil -> create_post(attrs)
      post -> update_post(post, attrs)
    end
  end

  @spec delete_post(Post.t()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t(Post.t())}
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end
end
