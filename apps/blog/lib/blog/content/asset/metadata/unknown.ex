defmodule Blog.Content.Asset.Metadata.Unknown do
  @moduledoc """
  Fallback metadata for unknown asset types.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :size_bytes, :integer
  end

  @doc false
  def changeset(metadata, attrs) do
    metadata
    |> cast(attrs, [:size_bytes])
    |> validate_number(:size_bytes, greater_than_or_equal_to: 0)
  end
end
