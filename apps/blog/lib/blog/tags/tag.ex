defmodule Blog.Tags.Tag do
  @moduledoc false
  use Blog.Schema

  @castable_fields [:label]

  schema "tags" do
    field :label, :string

    many_to_many :posts, Blog.Posts.Post, join_through: "posts_tags"
    many_to_many :projects, Blog.Projects.Project, join_through: "projects_tags"

    timestamps()
  end

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, @castable_fields)
    |> validate_required([:label])
    |> unique_constraint(:label)
  end
end
