defmodule BlogWeb.Components.Gallery do
  @moduledoc """
  Components for the component gallery page.
  """
  use Phoenix.Component

  @doc """
  Renders a gallery item section with title, description, and preview content.
  """
  attr :title, :string, required: true
  attr :description, :string, default: nil
  slot :inner_block, required: true

  def item(assigns) do
    ~H"""
    <section>
      <h2>{@title}</h2>
      <p :if={@description}>{@description}</p>
      <div class="component-preview">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end
end
