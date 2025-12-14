defmodule BlogWeb.Components.TableOfContents do
  @moduledoc """
  Table of contents component for displaying post navigation.
  """
  use Phoenix.Component

  @doc """
  Renders a table of contents from post headings.

  ## Attributes

    * `headings` - List of heading maps with :title, :link, and :level
    * `id` - DOM ID for the table of contents container
  """
  attr :headings, :list, required: true
  attr :id, :string, default: "toc"

  def toc(assigns) do
    ~H"""
    <nav id={@id} class="toc" aria-label="Table of contents">
      <%= if @headings == [] do %>
        <p>No headings available</p>
      <% else %>
        <ol class="toc-list">
          <%= for heading <- @headings do %>
            <li class="toc-item" data-level={heading.level} data-heading-id={heading.link}>
              <a href={"##{heading.link}"} class="toc-link">
                {heading.title}
              </a>
            </li>
          <% end %>
        </ol>
      <% end %>
    </nav>
    """
  end
end
