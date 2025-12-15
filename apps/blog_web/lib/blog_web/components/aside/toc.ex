defmodule BlogWeb.Components.Aside.Toc do
  @moduledoc """
  Table of contents component for displaying post navigation.
  """
  use Phoenix.Component

  alias BlogWeb.Components.Aside

  @doc """
  Renders a table of contents from post headings.

  ## Attributes

    * `headings` - List of heading maps with :title, :link, and :level
    * `id` - DOM ID for the table of contents container
    * `open` - Default open state (default: true)
  """
  attr :headings, :list, required: true
  attr :id, :string, default: "toc"
  attr :open, :boolean, default: true

  def toc(assigns) do
    ~H"""
    <Aside.aside_section title="Table of Contents" id={"#{@id}-wrapper"} open={@open}>
      <nav class="toc" phx-hook=".Scrollspy" id={@id} aria-label="Table of contents">
        <%= if @headings == [] do %>
          <p class="toc-empty">No headings available</p>
        <% else %>
          <ol class="toc-list" aria-live="polite">
            <%= for heading <- @headings do %>
              <li class="toc-item" data-level={heading.level} data-heading-id={heading.link}>
                <a href={"##{heading.link}"} class="toc-link">
                  <span class="toc-marker">{String.duplicate("#", heading.level)}</span>
                  {heading.title}
                </a>
              </li>
            <% end %>
          </ol>
        <% end %>
      </nav>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".Scrollspy">
        export default {
          mounted() {
            const headingIds = Array.from(this.el.querySelectorAll('[data-heading-id]'))
              .map(item => item.getAttribute('data-heading-id'));

            const headings = headingIds
              .map(id => document.getElementById(id))
              .filter(el => el !== null);

            if (headings.length === 0) return;

            // NOTE: Cache heading positions on mount to avoid layout thrashing.
            const headingPositions = headings.map(h => ({ id: h.id, top: h.offsetTop }));

            const SCROLL_OFFSET = 100;

            const updateActive = () => {
              const scrollTop = window.scrollY + SCROLL_OFFSET;
              let activeId = headingPositions[0].id;

              for (const pos of headingPositions) {
                if (pos.top <= scrollTop) {
                  activeId = pos.id;
                } else {
                  break;
                }
              }

              this.el.querySelectorAll('[data-active]').forEach(item => {
                delete item.dataset.active;
              });

              const activeItem = this.el.querySelector(`[data-heading-id="${activeId}"]`);
              if (activeItem) {
                activeItem.dataset.active = 'true';
              }
            };

            // Throttle scroll updates to once per animation frame (60fps) for performance
            let ticking = false;
            this.handleScroll = () => {
              if (!ticking) {
                requestAnimationFrame(() => {
                  updateActive();
                  ticking = false;
                });
                ticking = true;
              }
            };

            this.scrollOptions = { passive: true };
            window.addEventListener('scroll', this.handleScroll, this.scrollOptions);

            requestAnimationFrame(() => updateActive());
          },

          destroyed() {
            if (this.handleScroll) {
              window.removeEventListener('scroll', this.handleScroll, this.scrollOptions);
            }
          }
        }
      </script>
    </Aside.aside_section>
    """
  end
end
