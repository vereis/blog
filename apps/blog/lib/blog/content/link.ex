defmodule Blog.Content.Link do
  @moduledoc """
  Schema for bidirectional links between content items.

  Links are stored without foreign key constraints to allow broken links.
  The context field distinguishes between body wikilinks and tag associations.
  """
  use Blog.Schema

  @type context :: :body | :tag

  @contexts [:body, :tag]

  @primary_key false

  schema "content_links" do
    field :source_slug, :string, primary_key: true
    field :target_slug, :string, primary_key: true
    field :context, :string, primary_key: true

    timestamps()
  end

  @doc """
  Returns the list of valid link contexts.
  """
  @spec contexts() :: [context()]
  def contexts, do: @contexts

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(link, attrs) do
    link
    |> cast(attrs, [:source_slug, :target_slug, :context])
    |> validate_required([:source_slug, :target_slug, :context])
    |> validate_inclusion(:context, Enum.map(@contexts, &Atom.to_string/1))
    |> unique_constraint([:source_slug, :target_slug, :context], name: :content_links_pkey)
  end

  @impl EctoUtils.Queryable
  def base_query(queryable \\ __MODULE__), do: queryable

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {:source_slug, slug}, query when is_binary(slug) ->
        from link in query, where: link.source_slug == ^slug

      {:target_slug, slug}, query when is_binary(slug) ->
        from link in query, where: link.target_slug == ^slug

      {:context, context}, query when is_atom(context) ->
        from link in query, where: link.context == ^Atom.to_string(context)

      {:context, context}, query when is_binary(context) ->
        from link in query, where: link.context == ^context

      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end
end
