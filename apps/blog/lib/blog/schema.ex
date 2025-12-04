defmodule Blog.Schema do
  @moduledoc """
  Provides common schema functionality for all Blog schemas.

  ## Usage

      defmodule Blog.Posts.Post do
        use Blog.Schema

        schema "posts" do
          # ...
        end
      end

  This automatically includes:
  - `use Ecto.Schema`
  - `use EctoUtils.Schema, repo: Blog.Repo`
  - `use EctoUtils.Queryable`
  - `import Ecto.Changeset`
  - `import Ecto.Query`
  - Common type definitions (`@type t :: %__MODULE__{}`)
  - Alias for the current module as `__MODULE__`
  """

  defmacro __using__(_opts) do
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
