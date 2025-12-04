defmodule Blog.Projects.Project do
  @moduledoc false
  use Blog.Schema

  use Blog.Resource,
    source_dir: "priv/projects",
    on_conflict: [
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :name
    ]

  @castable_fields [:name, :url, :description, :hash]

  schema "projects" do
    field :name, :string
    field :url, :string
    field :description, :string
    field :hash, :string

    many_to_many :tags, Blog.Tags.Tag, join_through: "projects_tags"

    timestamps()
  end

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(project, attrs) do
    project
    |> cast(attrs, @castable_fields)
    |> validate_required([:name, :url, :description])
    |> unique_constraint(:name)
  end

  @impl Blog.Resource
  def handle_import(%Blog.Resource{content: content}) do
    case YamlElixir.read_from_string(content) do
      {:ok, %{"projects" => projects}} when is_list(projects) ->
        Enum.map(projects, fn project ->
          attrs =
            project
            |> Map.take(Enum.map(@castable_fields -- [:hash], &Atom.to_string/1))
            |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)

          changeset(%__MODULE__{}, attrs)
        end)

      {:ok, yaml_without_projects} ->
        {:error, "YAML content does not contain 'projects' key with a list value, got: #{inspect(yaml_without_projects)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
