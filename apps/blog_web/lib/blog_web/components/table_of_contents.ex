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
    <nav id={@id} class="toc" phx-hook=".Scrollspy" aria-label="Table of contents">
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

    <script :type={Phoenix.LiveView.ColocatedHook} name=".Scrollspy">
      export default {
        mounted() {
          // Find all headings in the post body that match TOC entries
          const headingIds = Array.from(this.el.querySelectorAll('[data-heading-id]'))
            .map(item => item.getAttribute('data-heading-id'));

          const headings = headingIds
            .map(id => document.getElementById(id))
            .filter(el => el !== null);

          if (headings.length === 0) return;

          // Create IntersectionObserver to track visible headings
          const observerOptions = {
            // Trigger when heading is near the top of viewport
            rootMargin: '-20% 0px -70% 0px',
            threshold: 0
          };

          this.observer = new IntersectionObserver((entries) => {
            // Find all currently visible headings
            const visibleHeadings = entries
              .filter(entry => entry.isIntersecting)
              .map(entry => entry.target.id);

            // Clear all active states
            this.el.querySelectorAll('[data-active]').forEach(item => {
              delete item.dataset.active;
            });

            // If we have visible headings, mark the first one as active
            if (visibleHeadings.length > 0) {
              const activeId = visibleHeadings[0];
              const activeItem = this.el.querySelector(`[data-heading-id="${activeId}"]`);
              if (activeItem) {
                activeItem.dataset.active = 'true';
              }
            }
          }, observerOptions);

          // Observe all headings
          headings.forEach(heading => this.observer.observe(heading));
        },

        destroyed() {
          // Clean up observer when component is destroyed
          if (this.observer) {
            this.observer.disconnect();
          }
        }
      }
    </script>
    """
  end
end
