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
    # credo:disable-for-next-line Credo.Check.Refactor.Apply
    :dev = apply(Mix, :env, [])
    "apps/blog/priv/images"
  rescue
    _e ->
      :blog
      |> :code.priv_dir()
      |> Path.join("images")
  end

  @impl Blog.Resource
  def parse(filename) do
    %{path: Path.join([source(), filename])}
  end

  @impl Blog.Resource
  def import(parsed_images) do
    for parsed_image <- parsed_images do
      {:ok, %Image{}} = Images.upsert_image(parsed_image)
    end

    :ok
  end
end
