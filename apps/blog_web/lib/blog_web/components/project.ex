defmodule BlogWeb.Components.Project do
  @moduledoc """
  Project-related components for displaying project listings.
  """
  use Phoenix.Component

  alias BlogWeb.Components.Badge
  alias BlogWeb.Components.Tag
  alias Phoenix.LiveView.LiveStream

  @base_url "/projects"

  @doc """
  Renders a list of projects with optional loading state.

  Displays project items, loading skeletons, or empty state based on the provided attributes.

  ## Attributes

    * `projects` - List of Project structs to display
    * `loading` - Boolean indicating if projects are being loaded (default: false)
    * `id` - DOM ID for the list (default: "projects")
    * `title` - Optional title to display above the list (default: "All Projects")

  ## Examples

      # In your LiveView mount:
      def mount(_params, _session, socket) do
        projects = Blog.Projects.list_projects()
        {:ok, assign(socket, projects: projects, loading: false, projects_empty: projects == [])}
      end

      # In your template with regular assigns:
      <Project.list projects={@projects} loading={@loading} empty={@projects_empty} />

      # With LiveView streams:
      def mount(_params, _session, socket) do
        projects = Blog.Projects.list_projects()

        socket =
          socket
          |> assign(:projects_empty, projects == [])
          |> stream(:projects, Enum.with_index(projects, 1))

        {:ok, socket}
      end

      <Project.list projects={@streams.projects} empty={@projects_empty} id="projects-stream" />
  """
  attr :projects, :any, default: [], doc: "List of Project structs or LiveView stream"
  attr :loading, :boolean, default: false
  attr :id, :string, default: "projects"
  attr :title, :string, default: "All Projects"
  attr :selected_tags, :list, default: []
  attr :rest, :global, doc: "Additional HTML attributes to add to the list element"

  def list(assigns) do
    assigns = assign(assigns, :base_url, @base_url)

    ~H"""
    <section>
      <Badge.badge id={"#{@id}-title"}>{@title}</Badge.badge>
      <%= cond do %>
        <% @loading -> %>
          <p id={"#{@id}-loading-text"} phx-hook=".ScrambleCount"><span data-count>0</span> items</p>
          <ol
            id={"#{@id}-loading"}
            class={["projects-list", "projects-loading"]}
            aria-busy="true"
            {@rest}
          >
            <.skeleton :for={_ <- 1..5} />
          </ol>
          <script :type={Phoenix.LiveView.ColocatedHook} name=".ScrambleCount">
            export default {
              mounted() {
                const span = this.el.querySelector('[data-count]');
                this.interval = setInterval(() => {
                  span.textContent = Math.floor(Math.random() * 10);
                }, 50);
              },
              destroyed() {
                clearInterval(this.interval);
              }
            }
          </script>
        <% match?(%LiveStream{inserts: []}, @projects) or @projects == [] -> %>
          <p>No items</p>
          <ol id={"#{@id}-empty"} class="projects-list" {@rest}>
            <li class="projects-list-empty">
              No projects yet. Check back soon!
            </li>
          </ol>
        <% true -> %>
          <p>{Enum.count(@projects)} items</p>
          <ol id={@id} class="projects-list" phx-update={phx_update(@projects)} {@rest}>
            <.item
              :for={{dom_id, {project, index}} <- normalize_projects(@projects)}
              id={dom_id}
              project={project}
              index={index}
              base_url={@base_url}
              selected_tags={@selected_tags}
            />
          </ol>
      <% end %>
    </section>
    """
  end

  defp skeleton(assigns) do
    ~H"""
    <li class="project-skeleton" aria-busy="true" aria-label="Loading project">
      <article>
        <div class="project-header">
          <span class="skeleton-text skeleton-index"></span>
          <div class="project-content">
            <span class="skeleton-text skeleton-name"></span>
            <span class="skeleton-text skeleton-description"></span>
            <span class="skeleton-text skeleton-meta"></span>
          </div>
        </div>
      </article>
    </li>
    """
  end

  defp item(assigns) do
    inserted_at = assigns.project.inserted_at

    {formatted_date, datetime_iso} =
      if inserted_at do
        {Calendar.strftime(inserted_at, "%b %d, %Y"), NaiveDateTime.to_iso8601(inserted_at)}
      else
        {nil, nil}
      end

    assigns =
      assigns
      |> assign(:formatted_date, formatted_date)
      |> assign(:datetime_iso, datetime_iso)

    ~H"""
    <li id={@id} class="project-item">
      <article>
        <div class="project-header">
          <span class="project-index">#{@index}</span>
          <div class="project-content">
            <h2 class="project-name">
              <a
                href={@project.url}
                target="_blank"
                rel="noopener noreferrer"
                aria-label={"View project: #{@project.name}"}
              >
                {@project.name}
              </a>
            </h2>
            <p class="project-description">{@project.description}</p>
            <div class="project-meta">
              <time :if={@project.inserted_at} datetime={@datetime_iso}>{@formatted_date}</time>
              <Tag.list
                :if={@project.tags != []}
                tags={@project.tags}
                base_url={@base_url}
                selected_tags={@selected_tags}
              />
            </div>
          </div>
        </div>
      </article>
    </li>
    """
  end

  defp phx_update(%LiveStream{}), do: "stream"
  defp phx_update(_), do: nil

  defp normalize_projects(%LiveStream{} = stream) do
    stream
  end

  defp normalize_projects(projects) when is_list(projects) do
    projects
    |> Enum.with_index(1)
    |> Enum.map(fn {project, index} -> {"project-#{project.id}", {project, index}} end)
  end
end
