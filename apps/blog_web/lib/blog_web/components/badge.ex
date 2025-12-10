defmodule BlogWeb.Components.Badge do
  @moduledoc """
  Badge component for displaying highlighted text.
  """
  use Phoenix.Component

  @doc """
  Renders a badge with colored background and text.

  ## Examples

      <.badge>Blog Title</.badge>

      <.badge class="custom-class">Custom Badge</.badge>
  """
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={["badge", @class]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
