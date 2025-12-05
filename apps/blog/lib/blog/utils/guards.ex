defmodule Blog.Utils.Guards do
  @moduledoc """
  Common guard macros used throughout the Blog application.
  """

  defguard valid?(changeset)
           when is_struct(changeset, Ecto.Changeset) and changeset.valid? == true

  defguard changes?(changeset, field)
           when is_struct(changeset, Ecto.Changeset) and is_map_key(changeset.changes, field)
end
