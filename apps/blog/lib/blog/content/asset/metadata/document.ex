defmodule Blog.Content.Asset.Metadata.Document do
  @moduledoc """
  Metadata for document assets like PDFs.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :page_count, :integer
    field :title, :string
    field :author, :string
  end

  @doc false
  def changeset(metadata, attrs) do
    metadata
    |> cast(attrs, [:page_count, :title, :author])
    |> validate_number(:page_count, greater_than: 0)
  end
end
