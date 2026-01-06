defmodule Blog.Content.Permalink do
  @moduledoc """
  Schema for URL permalinks that redirect to content slugs.

  Used by the PermalinkPlug to 301 redirect legacy URLs to current content locations.
  Permalinks are write-once (no updated_at) since paths should never change once created.
  """
  use Blog.Schema

  @primary_key {:path, :string, autogenerate: false}

  schema "permalinks" do
    field :content_slug, :string

    timestamps(updated_at: false)
  end

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(permalink, attrs) do
    permalink
    |> cast(attrs, [:path, :content_slug])
    |> validate_required([:path, :content_slug])
    |> unique_constraint(:path, name: :permalinks_pkey)
  end

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end
end
