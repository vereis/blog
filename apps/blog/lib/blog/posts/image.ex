defmodule Blog.Posts.Image do
  @moduledoc "An image."

  use Blog.Schema

  schema "images" do
    field(:path, :string)
    field(:name, :string)
    field(:data, :string)
    field(:width, :integer)
    field(:height, :integer)
    field(:content_type, :string)

    timestamps()
  end

  @spec changeset(t(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(%Image{} = image, attrs) do
    image
    |> cast(attrs, fields())
    |> optimize!()
    |> validate_required([:name, :data])
    |> unique_constraint(:name)
  end

  defp optimize!(changeset) do
    {:ok, image} =
      changeset
      |> Ecto.Changeset.get_field(:path)
      |> Vix.Vips.Image.new_from_file()

    {:ok, optimized_image} =
      Vix.Vips.Image.write_to_buffer(image, ".webp", Q: 80, strip: true)

    changeset
    |> put_change(:data, optimized_image)
    |> put_change(:width, Vix.Vips.Image.width(image))
    |> put_change(:height, Vix.Vips.Image.height(image))
    |> put_change(:content_type, "image/webp")
    |> put_change(
      :name,
      (changeset |> Ecto.Changeset.get_field(:path) |> Path.rootname() |> Path.basename()) <>
        ".webp"
    )
  end
end
