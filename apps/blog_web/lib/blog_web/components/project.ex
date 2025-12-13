defmodule BlogWeb.Components.Project do
  @moduledoc """
  Project-related components for displaying portfolio items.
  """
  use Phoenix.Component

  alias BlogWeb.Components.Badge
  alias BlogWeb.Components.EmptyState
  alias BlogWeb.Components.Search
  alias BlogWeb.Components.Tag

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
  attr :projects, :list, default: [], doc: "List of Project structs"
  attr :id, :string, default: "projects"
  attr :title, :string, default: "Projects"
  attr :all_tags, :list, default: []
  attr :selected_tags, :list, default: []
  attr :search_query, :string, default: ""
  attr :rest, :global, doc: "Additional HTML attributes to add to the list element"

  def list(assigns) do
    assigns = assign(assigns, :base_url, @base_url)

    ~H"""
    <section class="project-list-section">
      <Badge.badge id={"#{@id}-title"}>{@title}</Badge.badge>
      <Search.input
        value={@search_query}
        base_url={@base_url}
        placeholder="(Web || CLI) && !Boring"
        selected_tags={@selected_tags}
      />
      <Tag.filter
        :if={@all_tags != []}
        tags={@all_tags}
        base_url={@base_url}
        selected_tags={@selected_tags}
        search_query={@search_query}
      />
      <div class="project-list-content">
        <%= if @projects == [] do %>
          <p aria-live="polite">No items</p>
          <EmptyState.block>
            No projects found. <.link navigate="/">Return home</.link> or check back later!
          </EmptyState.block>
        <% else %>
          <p aria-live="polite">{length(@projects)} items</p>
          <ol id={@id} class="projects-list" {@rest}>
            <.item
              :for={{project, index} <- Enum.with_index(@projects, 1)}
              id={"project-#{project.id}"}
              project={project}
              index={index}
              base_url={@base_url}
              selected_tags={@selected_tags}
            />
          </ol>
        <% end %>
      </div>
    </section>
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
                search_query=""
              />
            </div>
          </div>
        </div>
      </article>
    </li>
    """
  end
end
