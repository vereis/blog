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
    <div
      class="bluescreen"
      id="bluescreen"
      phx-hook=".Bluescreen"
      data-href={@href}
      role="alert"
      aria-label="Error message"
    >
      <div class="bluescreen-header">
        <Badge.badge class="bluescreen-badge">Unexpected Error</Badge.badge>
      </div>
      <div class="bluescreen-content">
        <p>An error has occurred. To continue:</p>
        <p>Press <a href={@href}>Enter or Click</a> to return to the blog, or</p>
        <p>
          Press CTRL+ALT+DEL to restart your computer. If you do this, you will lose any unsaved information in all open applications and it probably won't fix the problem (maybe just try again later).
        </p>
        <p class="bluescreen-error-code">Error: {@error_code}</p>
        <p class="bluescreen-prompt">
          Press any key to continue<span class="bluescreen-cursor">█</span>
        </p>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Bluescreen">
      export default {
        mounted() {
          const href = this.el.dataset.href;
          const handleKeyPress = (e) => {
            window.location.href = href;
          };
          
          document.addEventListener('keydown', handleKeyPress);
          
          this.cleanup = () => {
            document.removeEventListener('keydown', handleKeyPress);
          };
        },
        
        destroyed() {
          if (this.cleanup) {
            this.cleanup();
          }
        }
      }
    </script>
    """
  end
end
