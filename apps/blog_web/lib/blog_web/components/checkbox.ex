defmodule BlogWeb.Components.Checkbox do
  @moduledoc """
  Generic checkbox component with localStorage persistence via colocated JS hook.

  Syncs checkbox state with body class and persists preference in localStorage.
  """
  use Phoenix.Component

  @doc """
  Renders a checkbox with label and localStorage persistence.

  ## Attributes

    * `id` - Unique DOM ID for the checkbox (required)
    * `storage_key` - localStorage key for persisting checkbox state (required)
    * `body_class` - CSS class to toggle on body element (required)
    * `label` - Text label displayed next to checkbox (required)
    * `checked` - Initial checked state (default: false)

  ## Examples

      <Checkbox.checkbox
        id="crt-filter-toggle"
        storage_key="crtFilter"
        body_class="crt-filter"
        label="CRT Filter"
      />
  """
  attr :id, :string, required: true
  attr :storage_key, :string, required: true
  attr :body_class, :string, required: true
  attr :label, :string, required: true
  attr :checked, :boolean, default: false

  def checkbox(assigns) do
    ~H"""
    <label class="checkbox-button">
      <span class="checkbox-box"></span>
      <input
        type="checkbox"
        id={@id}
        checked={@checked}
        phx-hook=".CheckboxToggle"
        data-storage-key={@storage_key}
        data-body-class={@body_class}
      />
      <span class="checkbox-label">{@label}</span>
    </label>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".CheckboxToggle">
      export default {
        mounted() {
          this.storageKey = this.el.dataset.storageKey;
          this.bodyClass = this.el.dataset.bodyClass;
          this.prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
          
          const stored = localStorage.getItem(this.storageKey);
          this.el.checked = stored === null ? !this.prefersReducedMotion : stored === 'true';
          
          this.handleChange = () => {
            const enabled = this.el.checked;
            
            try {
              localStorage.setItem(this.storageKey, enabled);
            } catch (error) {
              console.error('[CheckboxToggle] Failed to save preference:', error);
            }
            
            if (enabled && !this.prefersReducedMotion) {
              document.body.classList.add(this.bodyClass);
            } else {
              document.body.classList.remove(this.bodyClass);
            }
          };
          
          this.el.addEventListener('change', this.handleChange);
        },
        
        destroyed() {
          this.el.removeEventListener('change', this.handleChange);
        }
      }
    </script>
    """
  end
end
