defmodule BlogWeb.Components.Footer do
  @moduledoc """
  Site footer component with vim-style status line.
  """
  use Phoenix.Component

  @doc """
  Renders a vim-style footer with color-blocked sections.

  ## Examples

      <.footer />
  """
  def footer(assigns) do
    ~H"""
    <div class="site-footer">
      <div class="footer-left">
        <.link navigate="/rss" class="footer-block">RSS</.link>
        <span class="footer-copyright">© vereis {Date.utc_today().year}</span>
      </div>
      <.link
        href="https://github.com/vereis/blog"
        class="footer-block"
        target="_blank"
        rel="noopener noreferrer"
        aria-label="Source code (opens in new tab)"
      >
        Source
      </.link>
    </div>
    """
  end
end
