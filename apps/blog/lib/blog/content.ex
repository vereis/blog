defmodule Blog.Content do
  @moduledoc """
  Context module for content management (essays, notes, tags, projects).

  Content types are dynamic and determined by the first path segment of content slugs.
  """

  alias Blog.Content.Content
  alias Blog.Repo

  @doc """
  Returns the list of distinct content types currently in the database.

  Content types are derived from the first path segment of slugs
  (e.g., "essays/my-post" has type "essays").

  ## Examples

      iex> Blog.Content.types()
      ["essays", "notes", "projects", "tags"]

  """
  @spec types() :: [String.t()]
  def types do
    # NOTE: In the future, cache this in persistent term and add a
    # `refresh_types/0` function that can be called on import
    Content
    |> Content.query(select: :type, distinct: true)
    |> Repo.all()
  end
end
