defmodule Blog.Projects.Project do
  @moduledoc "A project entry."

  use Blog.Schema

  @dialyzer {:nowarn_function, association: 1}

  schema "projects" do
    field(:name, :string)
    field(:url, :string)
    field(:description, :string)

    timestamps()
  end

  @spec changeset(t(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = project, attrs) do
    project
    |> cast(attrs, [:name, :url, :description])
    |> validate_required([:name, :url, :description])
  end

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end
end
