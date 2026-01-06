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
  def base_query(queryable \\ __MODULE__), do: queryable

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {:path, path}, query when is_binary(path) ->
        from permalink in query, where: permalink.path == ^path

      {:content_slug, slug}, query when is_binary(slug) ->
        from permalink in query, where: permalink.content_slug == ^slug

      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end
end
