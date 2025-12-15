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
  """
  attr :headings, :list, required: true
  attr :id, :string, default: "toc"

  def toc(assigns) do
    ~H"""
    <Aside.aside_section title="Table of Contents" id={@id}>
      <nav class="toc" phx-hook=".Scrollspy" id={"#{@id}-nav"} aria-label="Table of contents">
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
            this.initScrollspy();
            this.setupScrollHandler();
          },

          updated() {
            const currentHeadingIds = Array.from(this.el.querySelectorAll('[data-heading-id]'))
              .map(item => item.getAttribute('data-heading-id'))
              .join(',');
            
            if (this.lastHeadingIds !== currentHeadingIds) {
              this.lastHeadingIds = currentHeadingIds;
              requestAnimationFrame(() => {
                this.initScrollspy();
              });
            }
          },

          destroyed() {
            if (this.handleScroll) {
              window.removeEventListener('scroll', this.handleScroll, this.scrollOptions);
            }
          },

          initScrollspy() {
            const headingIds = Array.from(this.el.querySelectorAll('[data-heading-id]'))
              .map(item => item.getAttribute('data-heading-id'));

            const headings = headingIds
              .map(id => document.getElementById(id))
              .filter(el => el !== null);

            if (headings.length === 0) {
              this.headingPositions = null;
              return;
            }

            this.lastHeadingIds = headingIds.join(',');
            this.headingPositions = headings.map(h => ({ id: h.id, top: h.offsetTop }));

            requestAnimationFrame(() => this.updateActive());
          },

          setupScrollHandler() {
            if (this.scrollHandlerInitialized) return;
            this.scrollHandlerInitialized = true;

            let ticking = false;
            this.handleScroll = () => {
              if (!ticking) {
                requestAnimationFrame(() => {
                  this.updateActive();
                  ticking = false;
                });
                ticking = true;
              }
            };

            this.scrollOptions = { passive: true };
            window.addEventListener('scroll', this.handleScroll, this.scrollOptions);
          },

          updateActive() {
            if (!this.headingPositions) return;
            
            const SCROLL_OFFSET = 100;
            const scrollTop = window.scrollY + SCROLL_OFFSET;
            let activeId = this.headingPositions[0].id;

            for (const pos of this.headingPositions) {
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
          }
        }
      </script>
    </Aside.aside_section>
    """
  end
end
