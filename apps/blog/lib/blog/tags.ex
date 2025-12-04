defmodule Blog.Tags do
  @moduledoc false

  alias Blog.Repo
  alias Blog.Tags.Tag

  @spec list_tags(Keyword.t()) :: [Tag.t()]
  def list_tags(filters \\ []) do
    filters
    |> Tag.query()
    |> Repo.all()
  end

  @spec get_tag(integer()) :: Tag.t() | nil
  @spec get_tag(Keyword.t()) :: Tag.t() | nil
  def get_tag(tag_id) when is_integer(tag_id) do
    get_tag(id: tag_id)
  end

  def get_tag(filters) when is_list(filters) do
    filters
    |> Keyword.put(:limit, 1)
    |> Tag.query()
    |> Repo.one()
  end

  @spec create_tag(map()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t(Tag.t())}
  def create_tag(attrs) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_tag(Tag.t(), map()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t(Tag.t())}
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @spec upsert_tag(map()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t(Tag.t())}
  def upsert_tag(attrs) when is_map(attrs) do
    case get_tag(label: Map.get(attrs, :label)) do
      nil -> create_tag(attrs)
      tag -> update_tag(tag, attrs)
    end
  end

  @spec delete_tag(Tag.t()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t(Tag.t())}
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @spec label_to_id(String.t() | [String.t()] | map()) :: integer() | [integer()] | map()
  def label_to_id(label) when is_binary(label) do
    %{label: label} |> upsert_tag() |> elem(1) |> Map.get(:id)
  end

  def label_to_id(labels) when is_list(labels) do
    Enum.map(labels, &label_to_id/1)
  end

  def label_to_id(entity) when is_map(entity) and is_map_key(entity, :tags) do
    Map.put(entity, :tag_ids, label_to_id(entity.tags))
  end
end
