defmodule BlogWeb.Components.Viewers do
  @moduledoc """
  Viewer count component for displaying real-time viewer statistics.
  """
  use Phoenix.Component

  @doc """
  Renders viewer count information in the aside.

  ## Examples

      <.counts site_count={@site_viewer_count} page_count={@page_viewer_count} />
  """
  attr :site_count, :integer, required: true
  attr :page_count, :integer, required: true
  attr :id, :string, default: "viewer-counts"

  def counts(assigns) do
    ~H"""
    <aside id={@id} class="viewer-counts" aria-label="Viewer Counts">
      <h2 class="aside-section-header">Viewers</h2>

      <p class="viewer-stat">
        <span class="viewer-bullet">•</span>
        <span class="viewer-label">Site-wide:</span>
        <span class="viewer-count">{@site_count}</span>
      </p>

      <p class="viewer-stat">
        <span class="viewer-bullet">•</span>
        <span class="viewer-label">This page:</span>
        <span class="viewer-count">{@page_count}</span>
      </p>
    </aside>
    """
  end
end
