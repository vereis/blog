defmodule Blog.Assets.Types do
  @moduledoc "Utility module for handling different asset types in `Blog.Assets.Asset`s"

  import Blog.Utils.Guards
  import Ecto.Changeset

  alias Blog.Assets.Types.Image
  alias Blog.Assets.Types.Unimplemented

  @callback handle_type(Ecto.Changeset.t()) :: Ecto.Changeset.t()

  @type_mapping %{
    image: Image,
    video: Unimplemented,
    document: Unimplemented,
    text: Unimplemented,
    unimplemented: Unimplemented
  }

  defmacro __using__(_opts) do
    caller = __CALLER__.module

    if caller not in Map.values(@type_mapping) do
      raise ArgumentError,
            "Please add your module #{inspect(caller)} to the `@type_mapping` in Blog.Assets.Types"
    end

    quote do
      @behaviour unquote(__MODULE__)

      import Blog.Utils.Guards
      import Ecto.Changeset

      @impl unquote(__MODULE__)
      def handle_type(changeset) do
        raise ArgumentError,
              "You must implement handle_type/1 in your module that uses Blog.Assets.Types"
      end

      defoverridable handle_type: 1
    end
  end

  @doc "Returns the list of supported asset types as atoms"
  defmacro enum do
    quote do
      unquote(Map.keys(@type_mapping)) -- [:unimplemented]
    end
  end

  @spec handle_type(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def handle_type(changeset) when changes?(changeset, :path) do
    type =
      changeset
      |> get_change(:path)
      |> MIME.from_path()
      |> case do
        "image/" <> _ -> :image
        "video/" <> _ -> :video
        "application/pdf" -> :document
        "text/" <> _ -> :text
        _other -> :unimplemented
      end

    changeset
    |> @type_mapping[type].handle_type()
    |> validate_required([:type, :name])
  end

  def handle_type(changeset) do
    changeset
  end
end
