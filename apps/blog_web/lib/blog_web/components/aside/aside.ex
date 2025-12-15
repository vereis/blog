defmodule BlogWeb.Components.Aside do
  @moduledoc """
  Shared aside section component with collapsible details/summary.

  Provides a reusable wrapper for aside sections that:
  - Uses native HTML `<details>`/`<summary>` for accessibility
  - Displays triangle indicators (`▶`/`▼`) matching the terminal theme
  - Defaults to open state on page load
  """
  use Phoenix.Component

  @doc """
  Renders a collapsible aside section with sessionStorage persistence.

  ## Attributes

    * `title` - The section header text (required)
    * `id` - Unique DOM ID (required)

  ## Examples

      <Aside.aside_section title="Presence" id="discord-presence">
        <p>Discord status content...</p>
      </Aside.aside_section>

      <Aside.aside_section title="Table of Contents" id="toc">
        <nav>...</nav>
      </Aside.aside_section>
  """
  attr :title, :string, required: true
  attr :id, :string, required: true
  slot :inner_block, required: true

  def aside_section(assigns) do
    ~H"""
    <details id={@id} class="aside-section" open phx-hook=".AsideCollapse">
      <summary class="aside-section-header">{@title}</summary>
      <div class="aside-section-content">
        {render_slot(@inner_block)}
      </div>
    </details>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".AsideCollapse">
      export default {
        mounted() {
          this.storageKey = `aside-collapse-${this.el.id}`;
          
          try {
            const stored = sessionStorage.getItem(this.storageKey);
            if (stored === 'false') {
              this.el.open = false;
            }
          } catch (error) {
            console.error('[AsideCollapse] Failed to restore state:', error);
          }
          
          this.toggleHandler = () => {
            try {
              sessionStorage.setItem(this.storageKey, this.el.open);
            } catch (error) {
              console.error('[AsideCollapse] Failed to save state:', error);
            }
          };
          
          this.el.addEventListener('toggle', this.toggleHandler);
        },

        updated() {
          if (this.reattachTimeout) {
            clearTimeout(this.reattachTimeout);
          }
          
          try {
            const stored = sessionStorage.getItem(this.storageKey);
            if (stored !== null) {
              const desiredState = stored === 'true';
              if (this.el.open !== desiredState) {
                this.el.removeEventListener('toggle', this.toggleHandler);
                this.el.open = desiredState;
                this.reattachTimeout = setTimeout(() => {
                  this.el.addEventListener('toggle', this.toggleHandler);
                  this.reattachTimeout = null;
                }, 0);
              }
            }
          } catch (error) {
            console.error('[AsideCollapse] Failed to restore state on update:', error);
          }
        },
        
        destroyed() {
          if (this.toggleHandler) {
            this.el.removeEventListener('toggle', this.toggleHandler);
          }
        }
      }
    </script>
    """
  end
end
