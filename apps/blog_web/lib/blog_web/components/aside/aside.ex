defmodule BlogWeb.Components.Aside do
  @moduledoc """
  Shared aside section component with collapsible details/summary.

  Provides a reusable wrapper for aside sections that:
  - Uses native HTML `<details>`/`<summary>` for accessibility
  - Persists collapse state in localStorage
  - Displays triangle indicators (`▶`/`▼`) matching the terminal theme
  """
  use Phoenix.Component

  @doc """
  Renders a collapsible aside section with localStorage persistence.

  ## Attributes

    * `title` - The section header text (required)
    * `id` - Unique DOM ID, also used as localStorage key (required)
    * `open` - Default open state, can be overridden by localStorage (default: true)

  ## Examples

      <Aside.aside_section title="Presence" id="discord-presence">
        <p>Discord status content...</p>
      </Aside.aside_section>

      <Aside.aside_section title="Table of Contents" id="toc" open={false}>
        <nav>...</nav>
      </Aside.aside_section>
  """
  attr :title, :string, required: true
  attr :id, :string, required: true
  attr :open, :boolean, default: true
  slot :inner_block, required: true

  def aside_section(assigns) do
    ~H"""
    <details id={@id} class="aside-section" open={@open} phx-hook=".AsideCollapse">
      <summary class="aside-section-header">{@title}</summary>
      <div class="aside-section-content">
        {render_slot(@inner_block)}
      </div>
    </details>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".AsideCollapse">
      export default {
        mounted() {
          const key = `aside-collapse-${this.el.id}`;
          const stored = localStorage.getItem(key);

          // Override default open state if user has a preference
          if (stored !== null) {
            this.el.open = stored === 'true';
          }

          // Save state to localStorage whenever toggled
          this.el.addEventListener('toggle', () => {
            localStorage.setItem(key, this.el.open);
          });
        }
      }
    </script>
    """
  end
end
