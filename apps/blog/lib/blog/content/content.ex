defmodule Blog.Content.Content do
  @moduledoc """
  Unified content schema for essays, notes, tags, and projects.

  Content type is derived from the first path segment of the slug
  (e.g., "essays/my-post" -> type: "essays").
  """
  use Blog.Schema

  @type content_type :: :essays | :notes | :tags | :projects

  @content_types [:essays, :notes, :tags, :projects]

  @primary_key {:slug, :string, autogenerate: false}

  schema "content" do
    field :type, :string
    field :title, :string
    field :source_path, :string
    field :raw_body, :string
    field :body, :string
    field :excerpt, :string
    field :description, :string
    field :external_url, :string
    field :is_draft, :boolean, default: false
    field :published_at, :utc_datetime
    field :reading_time_minutes, :integer
    field :permalinks, {:array, :string}, default: []
    field :deleted_at, :utc_datetime

    embeds_many :headings, Heading, primary_key: false, on_replace: :delete do
      field :link, :string
      field :title, :string
      field :level, :integer
    end

    timestamps()
  end

  @doc """
  Returns the list of valid content types.
  """
  @spec content_types() :: [content_type()]
  def content_types, do: @content_types

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(content, attrs) do
    content
    |> cast(attrs, [
      :slug,
      :type,
      :title,
      :source_path,
      :raw_body,
      :body,
      :excerpt,
      :description,
      :external_url,
      :is_draft,
      :published_at,
      :reading_time_minutes,
      :permalinks,
      :deleted_at
    ])
    |> validate_required([:slug, :type, :title, :source_path])
    |> validate_inclusion(:type, Enum.map(@content_types, &Atom.to_string/1))
    |> cast_embed(:headings, with: &heading_changeset/2)
  end

  defp heading_changeset(heading, attrs) do
    heading
    |> cast(attrs, [:link, :title, :level])
    |> validate_required([:link, :title, :level])
    |> validate_number(:level, greater_than: 0, less_than_or_equal_to: 6)
  end

  @impl EctoUtils.Queryable
  def base_query(queryable \\ __MODULE__) do
    from content in queryable, where: is_nil(content.deleted_at)
  end

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {:type, type}, query when is_atom(type) ->
        from content in query, where: content.type == ^Atom.to_string(type)

      {:type, type}, query when is_binary(type) ->
        from content in query, where: content.type == ^type

      {:is_draft, is_draft}, query ->
        from content in query, where: content.is_draft == ^is_draft

      {:slug, slug}, query when is_binary(slug) ->
        from content in query, where: content.slug == ^slug

      {:permalink, permalink}, query when is_binary(permalink) ->
        from content in query, where: ^permalink in content.permalinks

      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end
end
