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
    "image/svg+xml" => :image,
    "application/pdf" => :document,
    "application/msword" => :document,
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => :document,
    "audio/mpeg" => :audio,
    "audio/ogg" => :audio,
    "audio/wav" => :audio,
    "audio/webm" => :audio,
    "video/mp4" => :video,
    "video/webm" => :video,
    "video/ogg" => :video
  }

  @doc """
  Returns the metadata type atom for a given MIME content type.
  """
  @spec type_for_content_type(String.t()) :: atom()
  def type_for_content_type(content_type) do
    Map.get(@type_mappings, content_type, :unknown)
  end
end
