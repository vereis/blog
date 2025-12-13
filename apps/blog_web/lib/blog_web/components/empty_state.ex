defmodule BlogWeb.Components.EmptyState do
  @moduledoc """
  Empty state components with terminal-style aesthetic.
  """
  use Phoenix.Component

  @doc """
  Renders a block-level empty state with diagonal hatching pattern background.

  Creates a retro terminal-style empty state with backslash hatching (`\\\`) and
  a cleared area around the message text for optimal readability. Best used for
  major empty states like "no posts" or "no projects".

  ## Examples

      <EmptyState.block>
        No posts yet. Check back soon!
      </EmptyState.block>

      <EmptyState.block>
        No projects yet. <.link navigate="/">Return home</.link> or check back later!
      </EmptyState.block>
  """
  slot :inner_block, required: true, doc: "The message content to display"

  def block(assigns) do
    ~H"""
    <div class="empty-state" role="status">
      <div class="empty-state-message">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders an inline empty state message.

  Creates a simple, styled inline message for minor empty states like
  "no tags available" in filters. Uses muted text styling consistent
  with terminal aesthetic.

  ## Examples

      <EmptyState.inline>
        No tags available
      </EmptyState.inline>

      <EmptyState.inline>
        No results found for your search
      </EmptyState.inline>
  """
  slot :inner_block, required: true, doc: "The message content to display"

  def inline(assigns) do
    ~H"""
    <span class="empty-state-inline" role="status">
      {render_slot(@inner_block)}
    </span>
    """
  end
end
