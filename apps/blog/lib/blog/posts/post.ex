defmodule Blog.Posts.Post do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @castable_fields [:title, :raw_body, :slug, :is_draft, :published_at]

  schema "posts" do
    field :title, :string
    field :body, :string
    field :raw_body, :string
    field :slug, :string
    field :reading_time_minutes, :integer
    field :is_draft, :boolean, default: false
    field :published_at, :utc_datetime
    field :hash, :string

    embeds_many :headings, Heading, primary_key: false do
      field :link, :string
      field :title, :string
      field :level, :integer
    end

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, @castable_fields)
    |> validate_required([:title, :raw_body, :slug])
    |> unique_constraint(:slug)
  end
end
