defmodule Blog.Projects.Project do
  @moduledoc "A project entry."

  use Blog.Schema

  alias Blog.Posts.Tag
  alias Blog.Schema.FTS

  @dialyzer {:nowarn_function, association: 1}

  schema "projects" do
    field(:name, :string)
    field(:url, :string)
    field(:description, :string)

    field(:rank, :float, virtual: true)

    many_to_many(:tags, Tag,
      join_through: join_schema("projects_tags", {:project_id, :tag_id}),
      on_replace: :delete
    )

    timestamps()
  end

  @spec changeset(t(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = project, attrs) do
    project
    |> cast(attrs, fields())
    |> validate_required([:name, :url, :description])
    |> preload_put_assoc(attrs, :tags, :tag_ids)
  end

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {:search, search_term}, query ->
        case FTS.sanitize_fts_query(search_term) do
          sanitized when sanitized in [nil, ""] ->
            from project in query,
              order_by: [asc: :name]

          sanitized_term ->
            from project in query,
              join: fts in "projects_fts",
              on: project.id == fts.project_id,
              where: fragment("projects_fts MATCH ?", ^sanitized_term),
              order_by: [asc: fts.rank],
              select_merge: %{rank: fts.rank}
        end

      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end
end
