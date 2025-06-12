defmodule Blog.Images do
  @moduledoc "Context module for managing images."

  alias Blog.Images.Image
  alias Blog.Repo.SQLite

  @doc """
  Gets a single image by ID or filters.
  """
  @spec get_image(id :: integer()) :: Image.t() | nil
  @spec get_image(filters :: Keyword.t()) :: Image.t() | nil
  def get_image(image_id) when is_integer(image_id) do
    get_image(id: image_id)
  end

  def get_image(filters) do
    filters |> Image.query() |> SQLite.one()
  end

  @doc """
  Lists images with optional filters.
  """
  @spec list_images(filters :: Keyword.t()) :: [Image.t()]
  def list_images(filters \\ []) do
    filters |> Image.query() |> SQLite.all()
  end

  @doc """
  Creates or updates an image with the given attributes.
  """
  @spec upsert_image(attrs :: map()) :: {:ok, Image.t()} | {:error, Ecto.Changeset.t()}
  def upsert_image(attrs) do
    (get_image(path: attrs.path) || %Image{})
    |> Image.changeset(attrs)
    |> SQLite.insert_or_update()
  end
end
