defmodule Blog.Posts.Tag do
  @moduledoc "A tag for a post. Effectively a category that groups multiple posts together."

  use Blog.Schema

  alias Blog.Posts.Post

  schema "tags" do
    field :label, :string

    many_to_many :posts, Post,
      join_through: join_schema("posts_tags", {:tag_id, :post_id}),
      on_replace: :delete

    timestamps()
  end

  @spec changeset(t, attrs :: map) :: Ecto.Changeset.t()
  def changeset(%Tag{} = tag, attrs) do
    tag
    |> cast(attrs, fields())
    |> validate_required([:label])
    |> unique_constraint(:label)
    |> preload_put_assoc(attrs, :posts, :post_ids)
  end
end
