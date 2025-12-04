defmodule Blog.Assets.Asset do
  @moduledoc false
  use Blog.Schema

  use Blog.Resource,
    source_dir: "priv/assets",
    import: &Blog.Assets.upsert_asset/1

  alias Vix.Vips.Image, as: VixImage

  @castable_fields [:path]

  defguardp valid?(changeset)
            when is_struct(changeset, Ecto.Changeset) and changeset.valid? == true

  defguardp changes?(changeset, field)
            when is_struct(changeset, Ecto.Changeset) and is_map_key(changeset.changes, field)

  schema "assets" do
    field :name, :string
    field :path, :string
    field :data, :binary
    field :width, :integer
    field :height, :integer
    field :content_type, :string
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
    |> optimize_image()
  end

  @impl Blog.Resource
  def handle_import(%Blog.Resource{path: path}) do
    %{path: path}
  end

  defp optimize_image(changeset) when not valid?(changeset) do
    changeset
  end

  defp optimize_image(changeset) when not changes?(changeset, :path) do
    changeset
  end

  defp optimize_image(changeset) do
    path = get_change(changeset, :path)

    {:ok, image} = VixImage.new_from_file(path)
    {:ok, optimized_data} = VixImage.write_to_buffer(image, ".webp", Q: 80, strip: true)

    name =
      path
      |> Path.basename()
      |> Path.rootname()
      |> Kernel.<>(".webp")

    changeset
    |> put_change(:data, optimized_data)
    |> put_change(:width, VixImage.width(image))
    |> put_change(:height, VixImage.height(image))
    |> put_change(:content_type, "image/webp")
    |> put_change(:name, name)
    |> validate_required([:name, :data, :width, :height, :content_type])
  end
end
