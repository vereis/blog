defmodule BlogWeb.Components.Search do
  @moduledoc """
  Search input component with TUI aesthetic.

  Provides a debounced search input with FTS query syntax support,
  URL state management, and integration with tag filtering.
  """
  use Phoenix.Component

  alias BlogWeb.Utils.QueryParams

  @doc """
  Renders a search input filter with debounced updates.

  ## Attributes

    * `value` - Current search query (default: "")
    * `name` - Form field name (default: "q")
    * `placeholder` - Placeholder text (default: "Supports AND, OR, NOT...")
    * `base_url` - Base URL for building clear link (required)
    * `class` - Optional additional CSS classes

  ## Examples

      <Search.input
        value={@search_query}
        base_url="/posts"
        placeholder="(Distributed && Elixir) Or Fun"
      />
  """
  attr :value, :string, default: ""
  attr :name, :string, default: "q"
  attr :placeholder, :string, default: "Supports AND, OR, NOT..."
  attr :base_url, :string, required: true
  attr :selected_tags, :list, default: []
  attr :class, :string, default: nil

  def input(assigns) do
    assigns = assign(assigns, :clear_url, QueryParams.clear_search(assigns.base_url, assigns.selected_tags))

    ~H"""
    <fieldset class={["search-filter", @class]}>
      <legend class="search-filter-label">
        Filter by text<.link
          :if={@value != ""}
          patch={@clear_url}
          class="search-filter-clear"
          aria-label="Clear search"
        > (clear ✕)</.link>:
      </legend>
      <form phx-change="search" class="search-input-wrapper">
        <input
          type="text"
          name={@name}
          value={@value}
          placeholder={@placeholder}
          class="search-input"
          phx-debounce="350"
          autocomplete="off"
        />
      </form>
    </fieldset>
    """
  end

  @doc """
  Parses search query from URL query parameters.

  Extracts the search query from the specified query parameter key,
  trims whitespace, and returns empty string if not present.

  ## Examples

      iex> BlogWeb.Components.Search.query_from_params(%{"q" => "elixir fts"})
      "elixir fts"

      iex> BlogWeb.Components.Search.query_from_params(%{"q" => "  phoenix  "})
      "phoenix"

      iex> BlogWeb.Components.Search.query_from_params(%{})
      ""

      iex> BlogWeb.Components.Search.query_from_params(%{"search" => "test"}, "search")
      "test"

  """
  def query_from_params(params, key \\ "q")

  def query_from_params(params, key) when is_map_key(params, key) do
    params
    |> Map.get(key)
    |> to_string()
    |> String.trim()
  end

  def query_from_params(_params, _key) do
    ""
  end

  @doc """
  Builds query parameters string combining search and tags for URL.

  Delegates to `BlogWeb.Utils.QueryParams.build_params/2`.

  ## Examples

      iex> BlogWeb.Components.Search.build_query_params("elixir", ["phoenix"])
      "q=elixir&tags=phoenix"

      iex> BlogWeb.Components.Search.build_query_params("", ["phoenix", "ecto"])
      "tags=phoenix%2Cecto"

      iex> BlogWeb.Components.Search.build_query_params("test", [])
      "q=test"

      iex> BlogWeb.Components.Search.build_query_params("", [])
      ""

  """
  defdelegate build_query_params(search_query, selected_tags), to: QueryParams, as: :build_params
end
