defmodule Blog.Resource.Image do
  @moduledoc """
  Resource implementation for importing blog images.

  Implements the Blog.Resource behaviour to provide image-specific
  import functionality.
  """

  @behaviour Blog.Resource

  alias Blog.Images
  alias Blog.Images.Image

  @impl Blog.Resource
  def source do
    case Blog.env() do
      :dev ->
        "apps/blog/priv/images"

      _other ->
        :blog
        |> :code.priv_dir()
        |> Path.join("images")
    end
  end

  @impl Blog.Resource
  def parse(filename) do
    %{path: Path.join([source(), filename])}
  end

  @impl Blog.Resource
  def import(parsed_images) do
    imported_images =
      for parsed_image <- parsed_images do
        {:ok, %Image{} = imported_image} = Images.upsert_image(parsed_image)
        imported_image
      end

    {:ok, imported_images}
  end
end
