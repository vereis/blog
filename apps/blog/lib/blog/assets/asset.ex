defmodule Blog.Assets.Asset do
  @moduledoc false
  use Blog.Schema

  use Blog.Resource,
    source_dir: "priv/assets",
    import: &Blog.Assets.upsert_asset/1

  require Blog.Assets.Types, as: Types

  @castable_fields [:path]

  schema "assets" do
    field :name, :string
    field :path, :string
    field :data, :binary
    field :width, :integer
    field :height, :integer
    field :content_type, :string
    field :type, Ecto.Enum, values: Types.enum()
    field :hash, :string

    timestamps()
  end

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, @castable_fields)
    |> validate_required([:path])
    |> unique_constraint(:name)
    |> unique_constraint(:path)
    |> Types.handle_type()
  end

  @impl Blog.Resource
  def handle_import(%Blog.Resource{path: path}) do
    %{path: path}
  end
end
