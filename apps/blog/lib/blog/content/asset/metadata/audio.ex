defmodule Blog.Content.Asset.Metadata.Audio do
  @moduledoc """
  Metadata for audio assets.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :duration_seconds, :float
    field :bitrate, :integer
    field :channels, :integer
    field :sample_rate, :integer
  end

  @doc false
  def changeset(metadata, attrs) do
    metadata
    |> cast(attrs, [:duration_seconds, :bitrate, :channels, :sample_rate])
    |> validate_number(:duration_seconds, greater_than: 0)
    |> validate_number(:bitrate, greater_than: 0)
    |> validate_number(:channels, greater_than: 0)
    |> validate_number(:sample_rate, greater_than: 0)
  end
end
