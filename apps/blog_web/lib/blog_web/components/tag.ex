defmodule BlogWeb.Components.Tag do
  @moduledoc """
  Tag components for displaying and navigating content tags.
  """
  use Phoenix.Component

  alias Blog.Tags.Tag

  @doc """
  Renders a list of tags as navigation links.

  ## Attributes

    * `tags` - List of Tag structs to display
    * `class` - Optional additional CSS classes for the container
  """
  attr :tags, :list, required: true
  attr :class, :string, default: nil

  def list(assigns) do
    ~H"""
    <nav
      :if={@tags not in [nil, []]}
      class={["tags", @class]}
      aria-label="Tags"
    >
      <.single :for={tag <- @tags} tag={tag} href="#" />
    </nav>
    """
  end

  @doc """
  Renders a single tag as a link.

  ## Attributes

    * `tag` - A Tag struct or tag label string
    * `href` - Optional link destination (defaults to "#")
    * `class` - Optional additional CSS classes
  """
  attr :tag, :any, required: true
  attr :href, :string, default: "#"
  attr :class, :string, default: nil

  def single(assigns) do
    ~H"""
    <.link href={@href} class={["tag", @class]}>
      {"#{tag_label(@tag)}"}
    </.link>
    """
  end

  defp tag_label(%Tag{label: label}), do: label
  defp tag_label(label) when is_binary(label), do: label
end
