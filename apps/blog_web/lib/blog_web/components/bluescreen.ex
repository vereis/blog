defmodule BlogWeb.Components.Bluescreen do
  @moduledoc """
  Windows 95-style bluescreen error component.
  """
  use Phoenix.Component

  alias Blog.Utils.ErrorCode
  alias BlogWeb.Components.Badge

  @doc """
  Renders a Windows 95-style bluescreen error.

  ## Examples

      <.bluescreen error={nil} href="/" />

      <.bluescreen error={:not_found} href="/posts" />
  """
  attr :error, :any, required: true
  attr :href, :string, default: "/"

  def bluescreen(assigns) do
    assigns = assign(assigns, :error_code, ErrorCode.generate(assigns.error))

    ~H"""
    <div class="bluescreen" role="alert" aria-label="Error message">
      <div class="bluescreen-header">
        <Badge.badge class="bluescreen-badge">Unexpected Error</Badge.badge>
      </div>
      <div class="bluescreen-content">
        <p>An error has occurred. To continue:</p>
        <p>
          <.link navigate={@href}>Click here</.link> to return to the blog, or
        </p>
        <p>
          Press CTRL+ALT+DEL to restart your computer. If you do this, you will lose any unsaved information in all open applications and it probably won't fix the problem (maybe just try again later).
        </p>
        <p class="bluescreen-error-code">Error: {@error_code}</p>
        <p class="bluescreen-prompt">
          <.link navigate={@href}>Click to continue</.link>
          <span class="bluescreen-cursor">█</span>
        </p>
      </div>
    </div>
    """
  end
end
