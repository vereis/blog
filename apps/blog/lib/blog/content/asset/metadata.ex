defmodule Blog.Content.Asset.Metadata do
  @moduledoc """
  Helper module for asset metadata type resolution.
  The actual polymorphic embed is defined in `Blog.Content.Asset` schema.
  """

  @type_mappings %{
    "image/jpeg" => :image,
    "image/png" => :image,
    "image/gif" => :image,
    "image/webp" => :image,
    "image/svg+xml" => :image
  }

  @doc """
  Returns the metadata type atom for a given MIME content type.
  Returns nil for unsupported types.
  """
  @spec type_for_content_type(String.t()) :: atom() | nil
  def type_for_content_type(content_type) do
    Map.get(@type_mappings, content_type)
  end
end
