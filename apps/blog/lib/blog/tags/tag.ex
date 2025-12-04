defmodule Blog.Tags.Tag do
  @moduledoc false
  use Blog.Schema

  @castable_fields [:label]

  schema "tags" do
    field :label, :string

    many_to_many :posts, Blog.Posts.Post,
      join_through: join_schema("posts_tags", {:tag_id, :post_id}),
      on_replace: :delete

    many_to_many :projects, Blog.Projects.Project,
      join_through: join_schema("projects_tags", {:tag_id, :project_id}),
      on_replace: :delete

    timestamps()
  end

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, @castable_fields)
    |> validate_required([:label])
    |> unique_constraint(:label)
    |> preload_put_assoc(attrs, :posts, :post_ids)
    |> preload_put_assoc(attrs, :projects, :project_ids)
  end
end
