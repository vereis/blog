defmodule BlogWeb.CoreComponents do
  @moduledoc false
  use Phoenix.Component

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
