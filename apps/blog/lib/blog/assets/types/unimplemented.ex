defmodule Blog.Assets.Types.Unimplemented do
  @moduledoc "Placeholder module for unimplemented asset types in `Blog.Assets.Asset`s"

  use Blog.Assets.Types

  @impl Blog.Assets.Types
  def handle_type(changeset) do
    add_error(changeset, :type, "Asset type handling not implemented")
  end
end
