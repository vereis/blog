defmodule Blog.Content.Asset do
  @moduledoc """
  Schema for content assets stored in the database with binary data and polymorphic metadata.

  ## Slug Structure

  - `slug`: Full asset path serving as the primary key (e.g., `"essays/my-post/hero.webp"` or `"assets/avatar.webp"`)
  - `content_slug`: Optional reference to parent content for co-located assets (e.g., `"essays/my-post"`). 
    Null for global assets in the `assets/` directory.
  """
  use Blog.Schema

  import PolymorphicEmbed

  alias Blog.Content.Asset.Metadata

  @primary_key {:slug, :string, autogenerate: false}

  schema "content_assets" do
    field :content_slug, :string
    field :source_path, :string
    field :name, :string
    field :data, :binary
    field :data_hash, :string
    field :content_type, :string
    field :deleted_at, :utc_datetime

    polymorphic_embeds_one(:metadata,
      types: [
        image: Metadata.Image
      ],
      on_type_not_found: :changeset_error,
      on_replace: :update
    )

    timestamps()
  end

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:slug, :content_slug, :source_path, :name, :data, :data_hash, :content_type, :deleted_at])
    |> validate_required([:slug, :source_path, :name, :data, :data_hash, :content_type])
    |> cast_polymorphic_embed(:metadata)
  end

  @impl EctoUtils.Queryable
  def base_query(queryable \\ __MODULE__) do
    from asset in queryable, where: is_nil(asset.deleted_at)
  end

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end
end
