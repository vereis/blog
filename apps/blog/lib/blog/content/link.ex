defmodule Blog.Content.Link do
  @moduledoc """
  Schema for bidirectional links between content items.

  Links are stored without foreign key constraints to allow broken links.
  The context field distinguishes between body wikilinks and tag associations.

  ## Examples

  ### Body wikilinks (from markdown)
      
      # In markdown file
      Check out [[essays/other-post]] for more details.

      # Stored as
      %Link{
        source_slug: "essays/my-post",
        target_slug: "essays/other-post",
        context: "body"
      }

  ### Tag references (from frontmatter)

      # In frontmatter
      tags:
        - tags/elixir
        - tags/testing

      # Stored as
      %Link{source_slug: "essays/my-post", target_slug: "tags/elixir", context: "tag"}
      %Link{source_slug: "essays/my-post", target_slug: "tags/testing", context: "tag"}
  """
  use Blog.Schema

  import Ecto.Changeset

  @primary_key false

  schema "content_links" do
    field :source_slug, :string, primary_key: true
    field :target_slug, :string, primary_key: true
    field :context, Ecto.Enum, values: [:body, :tag], primary_key: true

    timestamps()
  end

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(link, attrs) do
    link
    |> cast(attrs, [:source_slug, :target_slug, :context])
    |> validate_required([:source_slug, :target_slug, :context])
    |> unique_constraint([:source_slug, :target_slug, :context],
      name: :content_links_source_slug_target_slug_context_index
    )
  end

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {:context, context}, query ->
        from link in query, where: link.context == ^to_string(context)

      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end
end
