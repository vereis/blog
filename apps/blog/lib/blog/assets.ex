defmodule Blog.Assets do
  @moduledoc false

  alias Blog.Assets.Asset
  alias Blog.Repo

  @spec list_assets(Keyword.t()) :: [Asset.t()]
  def list_assets(filters \\ []) do
    filters
    |> Asset.query()
    |> Repo.all()
  end

  @spec get_asset(integer()) :: Asset.t() | nil
  @spec get_asset(Keyword.t()) :: Asset.t() | nil
  def get_asset(asset_id) when is_integer(asset_id) do
    get_asset(id: asset_id)
  end

  def get_asset(filters) when is_list(filters) do
    filters
    |> Keyword.put(:limit, 1)
    |> Asset.query()
    |> Repo.one()
  end

  @spec create_asset(map()) :: {:ok, Asset.t()} | {:error, Ecto.Changeset.t(Asset.t())}
  def create_asset(attrs) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_asset(Asset.t(), map()) :: {:ok, Asset.t()} | {:error, Ecto.Changeset.t(Asset.t())}
  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Repo.update()
  end

  @spec upsert_asset(map()) :: {:ok, Asset.t()} | {:error, Ecto.Changeset.t(Asset.t())}
  def upsert_asset(attrs) when is_map(attrs) do
    case get_asset(path: Map.get(attrs, :path)) do
      nil -> create_asset(attrs)
      asset -> update_asset(asset, attrs)
    end
  end

  @spec delete_asset(Asset.t()) :: {:ok, Asset.t()} | {:error, Ecto.Changeset.t(Asset.t())}
  def delete_asset(%Asset{} = asset) do
    Repo.delete(asset)
  end
end
