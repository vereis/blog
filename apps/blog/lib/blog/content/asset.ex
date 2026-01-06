defmodule Blog.Content.Asset do
  @moduledoc """
  Schema for content assets stored in the database with binary data and polymorphic metadata.
  """
  use Blog.Schema

  import PolymorphicEmbed

  alias Blog.Content.Asset.Metadata

  @primary_key {:slug, :string, autogenerate: false}

  schema "assets" do
    field :content_slug, :string
    field :source_path, :string
    field :name, :string
    field :data, :binary
    field :data_hash, :string
    field :content_type, :string
    field :deleted_at, :utc_datetime

    polymorphic_embeds_one(:metadata,
      types: [
        image: Metadata.Image,
        document: Metadata.Document,
        audio: Metadata.Audio,
        video: Metadata.Video,
        unknown: Metadata.Unknown
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
      {:slug, slug}, query when is_binary(slug) ->
        from asset in query, where: asset.slug == ^slug

      {:content_slug, slug}, query when is_binary(slug) ->
        from asset in query, where: asset.content_slug == ^slug

      {:content_type, type}, query when is_binary(type) ->
        from asset in query, where: asset.content_type == ^type

      {:name, name}, query when is_binary(name) ->
        from asset in query, where: asset.name == ^name

      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end
end
