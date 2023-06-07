defmodule Blog.Posts.Post do
  @moduledoc "A blog post."

  use Blog.Schema

  alias Blog.Posts.Tag

  schema "posts" do
    field :title, :string
    field :body, :string, default: ""
    field :raw_body, :string, default: ""

    field :slug, :string
    field :reading_time_minutes, :integer, default: 0
    field :is_draft, :boolean, default: true
    field :published_at, :utc_datetime

    many_to_many :tags, Tag,
      join_through: join_schema("posts_tags", {:post_id, :tag_id}),
      on_replace: :delete

    timestamps()
  end

  @spec changeset(t(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, fields())
    |> validate_required([:title, :slug])
    |> preload_put_assoc(attrs, :tags, :tag_ids)
    |> unique_constraint(:slug)
  end
end
