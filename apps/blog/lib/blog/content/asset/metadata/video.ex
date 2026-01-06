defmodule Blog.Content.Asset.Metadata.Video do
  @moduledoc """
  Metadata for video assets.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :width, :integer
    field :height, :integer
    field :duration_seconds, :float
    field :frame_rate, :float
    field :has_audio, :boolean, default: false
  end

  @doc false
  def changeset(metadata, attrs) do
    metadata
    |> cast(attrs, [:width, :height, :duration_seconds, :frame_rate, :has_audio])
    |> validate_number(:width, greater_than: 0)
    |> validate_number(:height, greater_than: 0)
    |> validate_number(:duration_seconds, greater_than: 0)
    |> validate_number(:frame_rate, greater_than: 0)
  end
end
