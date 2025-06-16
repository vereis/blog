defmodule Blog.Images.Image do
  @moduledoc "An image."
  use Blog.Schema

  alias Vix.Vips.Image, as: VixImage

  @dialyzer {:nowarn_function, association: 1}

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
      |> VixImage.new_from_file()

    {:ok, optimized_image} =
      VixImage.write_to_buffer(image, ".webp", Q: 80, strip: true)

    optimized_image_name =
      changeset
      |> Ecto.Changeset.get_field(:path)
      |> Path.rootname()
      |> Path.basename()
      |> Kernel.<>(".webp")

    changeset
    |> put_change(:data, optimized_image)
    |> put_change(:width, VixImage.width(image))
    |> put_change(:height, VixImage.height(image))
    |> put_change(:content_type, "image/webp")
    |> put_change(:name, optimized_image_name)
  end
end
