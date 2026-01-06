defmodule Blog.Content.Asset.Metadata.Image do
  @moduledoc """
  Metadata for image assets including dimensions and LQIP data.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :width, :integer
    field :height, :integer
    field :lqip_hash, :integer
    field :format, :string
    field :has_alpha, :boolean, default: false
  end

  @doc false
  def changeset(metadata, attrs) do
    metadata
    |> cast(attrs, [:width, :height, :lqip_hash, :format, :has_alpha])
    |> validate_required([:width, :height, :format])
    |> validate_number(:width, greater_than: 0)
    |> validate_number(:height, greater_than: 0)
  end
end
