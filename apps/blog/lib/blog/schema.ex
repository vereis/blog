defmodule Blog.Schema do
  @moduledoc "Module for extended ecto, shared schema, functionality."

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      use EctoUtils.Schema, repo: Blog.Repo
      use EctoUtils.Queryable

      import Ecto.Changeset
      import Ecto.Query

      alias __MODULE__

      @type t :: %__MODULE__{}
    end
  end
end
