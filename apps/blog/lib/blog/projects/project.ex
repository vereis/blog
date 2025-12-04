defmodule Blog.Projects.Project do
  @moduledoc false
  use Blog.Schema

  @castable_fields [:name, :url, :description, :hash]

  schema "projects" do
    field :name, :string
    field :url, :string
    field :description, :string
    field :hash, :string

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
end
