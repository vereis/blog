defmodule Blog.Posts.Image do
  @moduledoc "An image."

  use Blog.Schema

  schema "images" do
    field(:name, :string)
    field(:data, :string)
    field(:content_type, :string)

    timestamps()
  end

  @spec changeset(t(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(%Image{} = image, attrs) do
    image
    |> cast(attrs, fields())
    |> validate_required([:name, :data])
    |> unique_constraint(:name)
  end
end
