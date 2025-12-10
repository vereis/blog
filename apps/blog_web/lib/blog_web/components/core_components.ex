defmodule BlogWeb.CoreComponents do
  @moduledoc false
  use Phoenix.Component

  alias Blog.Utils.ErrorCode
  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={["flash", "flash-#{@kind}"]}
      {@rest}
    >
      <.icon :if={@kind == :info} name="info" />
      <.icon :if={@kind == :error} name="error" />
      <div class="flash-content">
        <p :if={@title} class="flash-title">{@title}</p>
        <p>{msg}</p>
      </div>
      <button type="button" class="flash-close" aria-label="close">
        <.icon name="close" />
      </button>
    </div>
    """
  end

  @doc """
  Renders a state message with an icon and colored border.

  ## Examples

      <.state_message kind={:info}>
        Loading your content...
      </.state_message>

      <.state_message kind={:error}>
        Failed to load. Please try again.
      </.state_message>

      <.state_message kind={:loading}>
        <.icon name="spinner" class="icon-spin" />
        <span>Processing...</span>
      </.state_message>
  """
  attr :id, :string, default: nil
  attr :kind, :atom, values: [:info, :error, :loading], required: true

  slot :inner_block, required: true

  def state_message(assigns) do
    ~H"""
    <div id={@id} class={["state-message", to_string(@kind)]}>
      <.icon :if={@kind == :info} name="info" />
      <.icon :if={@kind == :error} name="error" />
      <.icon :if={@kind == :loading} name="spinner" class="icon-spin" />
      <div>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a Windows 95-style bluescreen error.

  ## Examples

      <.bluescreen error={nil}>
        No blog post found. The system has become unstable.
      </.bluescreen>

      <.bluescreen error={:not_found}>
        Press any key to panic.
      </.bluescreen>
  """
  attr :error, :any, required: true

  slot :inner_block, required: true

  def bluescreen(assigns) do
    assigns = assign(assigns, :error_code, ErrorCode.generate(assigns.error))

    ~H"""
    <div class="bluescreen" id="bluescreen" phx-hook=".Bluescreen">
      <div class="bluescreen-badge">Unexpected Error</div>
      <div class="bluescreen-content">
        <p class="bluescreen-message">{render_slot(@inner_block)}</p>
        <p class="bluescreen-error-code">Error: {@error_code}</p>
        <p class="bluescreen-prompt">
          Press any key to continue<span class="bluescreen-cursor"> </span>
        </p>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Bluescreen">
      export default {
        mounted() {
          const handleKeyPress = (e) => {
            if (e.key === 'Enter') {
              window.location.href = '/';
            }
          };
          
          document.addEventListener('keydown', handleKeyPress);
          
          this.handleEvent = () => {
            document.removeEventListener('keydown', handleKeyPress);
          };
        },
        
        destroyed() {
          if (this.handleEvent) {
            this.handleEvent();
          }
        }
      }
    </script>
    """
  end

  @doc """
  Renders the site-wide navigation bar with links to main sections.

  ## Examples

      <.navbar />
  """
  def navbar(assigns) do
    ~H"""
    <header>
      <nav>
        <ul>
          <li><.link navigate="/">Home</.link></li>
          <li><.link navigate="/posts">Posts</.link></li>
          <li><.link navigate="/projects">Projects</.link></li>
        </ul>
      </nav>
    </header>
    """
  end

  @doc """
  Renders an ASCII/Unicode icon for terminal aesthetic.

  ## Available icons

    * `info` - ℹ
    * `error` - ⚠
    * `close` - ✕
    * `spinner` - ↻

  ## Examples

      <.icon name="info" />
      <.icon name="spinner" class="icon-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: nil

  def icon(assigns) do
    icons = %{
      "info" => "ℹ",
      "error" => "⚠",
      "close" => "✕",
      "spinner" => "↻"
    }

    assigns = assign(assigns, :glyph, Map.get(icons, assigns.name, "?"))

    ~H"""
    <span class={["icon", "icon-#{@name}", @class]} aria-hidden="true">{@glyph}</span>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js, to: selector)
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js, to: selector)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # You can make use of gettext to translate error messages by
    # uncommenting and adjusting the following code:

    # if count = opts[:count] do
    #   Gettext.dngettext(BlogWeb.Gettext, "errors", msg, msg, count, opts)
    # else
    #   Gettext.dgettext(BlogWeb.Gettext, "errors", msg, opts)
    # end

    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
