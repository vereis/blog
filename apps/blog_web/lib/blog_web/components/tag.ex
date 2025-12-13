defmodule BlogWeb.Components.Tag do
  @moduledoc """
  Tag components for displaying and navigating content tags.
  """
  use Phoenix.Component

  alias Blog.Tags.Tag
  alias BlogWeb.Components.EmptyState
  alias BlogWeb.Utils.QueryParams

  @doc """
  Renders a list of tags as navigation links.

  ## Attributes

    * `tags` - List of Tag structs to display
    * `class` - Optional additional CSS classes for the container
    * `base_url` - Base URL for filter links (e.g., "/posts")
    * `selected_tags` - List of currently selected tag labels
    * `search_query` - Current search query to preserve in URLs
  """
  attr :tags, :list, required: true
  attr :class, :string, default: nil
  attr :base_url, :string, required: true
  attr :selected_tags, :list, default: []
  attr :search_query, :string, default: ""

  def list(assigns) do
    assigns = assign(assigns, :selected_set, MapSet.new(assigns.selected_tags))

    ~H"""
    <nav
      :if={@tags not in [nil, []]}
      class={["tags", @class]}
      aria-label="Tags"
    >
      <.single
        :for={tag <- @tags}
        tag={tag}
        href={tag_filter_href(@base_url, tag, @selected_tags, @search_query)}
        selected={MapSet.member?(@selected_set, tag_label(tag))}
      />
    </nav>
    """
  end

  @doc """
  Renders a single tag as a link.

  ## Attributes

    * `tag` - A Tag struct or tag label string
    * `href` - Optional link destination (defaults to "#")
    * `class` - Optional additional CSS classes
    * `selected` - Whether this tag is currently selected/active
  """
  attr :tag, :any, required: true
  attr :href, :string, default: "#"
  attr :class, :string, default: nil
  attr :selected, :boolean, default: false

  def single(assigns) do
    ~H"""
    <.link
      patch={@href}
      class={["tag", @selected && "tag-active", @class]}
      aria-current={@selected && "true"}
    >
      {tag_label(@tag)}
    </.link>
    """
  end

  @doc """
  Renders tag filter bar with all available tags and active filter display.

  ## Attributes

    * `tags` - List of all available Tag structs
    * `selected_tags` - List of currently selected tag labels
    * `base_url` - Base URL for filter links (e.g., "/posts")
  """
  attr :tags, :list, required: true
  attr :selected_tags, :list, default: []
  attr :base_url, :string, required: true
  attr :search_query, :string, default: ""

  def filter(assigns) do
    assigns =
      assigns
      |> assign(:selected_set, MapSet.new(assigns.selected_tags))
      |> assign(:clear_url, QueryParams.clear_tags(assigns.base_url, assigns.search_query))

    ~H"""
    <fieldset class="tag-filter">
      <legend class="tag-filter-label">
        Filter by tag<.link
          :if={@selected_tags != []}
          patch={@clear_url}
          class="tag-filter-clear"
          aria-label="Clear all tag filters"
        > (clear ✕)</.link>:
      </legend>
      <nav class="tags" aria-label="Filter tags">
        <%= if @tags == [] do %>
          <EmptyState.inline>No tags available</EmptyState.inline>
        <% else %>
          <.single
            :for={tag <- @tags}
            tag={tag}
            href={tag_filter_href(@base_url, tag, @selected_tags, @search_query)}
            selected={MapSet.member?(@selected_set, tag_label(tag))}
          />
        <% end %>
      </nav>
    </fieldset>
    """
  end

  @doc """
  Parses tag labels from URL query parameters.

  Extracts comma-separated tag labels from the specified query parameter key,
  trims whitespace, and filters out empty strings.

  ## Examples

      iex> BlogWeb.Components.Tag.labels_from_params(%{"tags" => "elixir,phoenix"})
      ["elixir", "phoenix"]

      iex> BlogWeb.Components.Tag.labels_from_params(%{"tags" => "elixir, phoenix , "})
      ["elixir", "phoenix"]

      iex> BlogWeb.Components.Tag.labels_from_params(%{})
      []

      iex> BlogWeb.Components.Tag.labels_from_params(%{"categories" => "web,api"}, "categories")
      ["web", "api"]

  """
  def labels_from_params(params, key \\ "tags")

  def labels_from_params(params, key) when is_map_key(params, key) do
    params
    |> Map.get(key)
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  def labels_from_params(_params, _key) do
    []
  end

  @doc false
  def tag_label(%Tag{label: label}) do
    label
  end

  def tag_label(label) when is_binary(label) do
    label
  end

  @doc false
  def tag_filter_href(base_url, tag, selected, search_query \\ "") do
    new_selected_tags = QueryParams.toggle_tag(selected, tag_label(tag))
    QueryParams.build_url(base_url, search_query, new_selected_tags)
  end
end
