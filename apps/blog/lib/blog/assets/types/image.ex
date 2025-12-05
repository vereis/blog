defmodule Blog.Assets.Types.Image do
  @moduledoc "Handles image asset processing for changing image type `Blog.Assets.Asset`s"

  use Blog.Assets.Types

  alias Vix.Vips.Image, as: VixImage

  @impl Blog.Assets.Types
  def handle_type(changeset) do
    optimize_image(changeset)
  end

  defp optimize_image(changeset) when not valid?(changeset) do
    changeset
  end

  defp optimize_image(changeset) when not changes?(changeset, :path) do
    changeset
  end

  defp optimize_image(changeset) do
    path = get_change(changeset, :path)

    with {:ok, image} <- VixImage.new_from_file(path),
         {:ok, optimized_data} <- VixImage.write_to_buffer(image, ".webp", Q: 80, strip: true) do
      name =
        path
        |> Path.basename()
        |> Path.rootname()
        |> Kernel.<>(".webp")

      changeset
      |> put_change(:data, optimized_data)
      |> put_change(:width, VixImage.width(image))
      |> put_change(:height, VixImage.height(image))
      |> put_change(:content_type, "image/webp")
      |> put_change(:type, :image)
      |> put_change(:name, name)
      |> validate_required([:data, :width, :height, :content_type])
    else
      {:error, reason} ->
        add_error(changeset, :path, "Failed to process image: #{inspect(reason)}")
    end
  end
end
