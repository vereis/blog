defmodule Blog.Projects.Project do
  @moduledoc false
  use Blog.Schema

  use Blog.Content,
    source_dir: "priv/content/projects",
    preprocess: &Blog.Tags.label_to_id/1,
    import: &Blog.Projects.upsert_project/1

  import Blog.Utils.Guards

  alias Blog.Schema.FTS

  @castable_fields [:name, :url, :description]

  schema "projects" do
    field :name, :string
    field :url, :string
    field :description, :string

    many_to_many :tags, Blog.Tags.Tag,
      join_through: join_schema("projects_tags", {:project_id, :tag_id}),
      on_replace: :delete

    timestamps()
  end

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(project, attrs) do
    project
    |> cast(attrs, @castable_fields)
    |> validate_required([:name, :url, :description])
    |> unique_constraint(:name)
    |> preload_put_assoc(attrs, :tags, :tag_ids)
  end

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {:search, search_term}, query ->
        case FTS.sanitize_fts_query(search_term) do
          nil ->
            from project in query, order_by: [asc: :name]

          sanitized_term ->
            from project in query,
              join: fts in "projects_fts",
              on: project.id == fts.project_id,
              where: fragment("projects_fts MATCH ?", ^sanitized_term),
              order_by: [asc: fts.rank]
        end

      {:tags, tags}, query when empty?(tags) ->
        query

      {:tags, tags}, query ->
        from project in query,
          join: t in assoc(project, :tags),
          where: t.label in ^tags,
          distinct: true

      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end

  @impl Blog.Content
  def handle_import(%Blog.Content{content: content}) do
    case YamlElixir.read_from_string(content) do
      {:ok, %{"projects" => projects}} when is_list(projects) ->
        Enum.map(projects, fn project ->
          attrs =
            project
            |> Map.take(Enum.map(@castable_fields, &Atom.to_string/1))
            |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)

          Map.put(attrs, :tags, Map.get(project, "tags", []))
        end)

      {:ok, yaml_without_projects} ->
        {:error, "YAML content does not contain 'projects' key with a list value, got: #{inspect(yaml_without_projects)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
