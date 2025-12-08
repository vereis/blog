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
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="info" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="error" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label="close">
          <.icon name="close" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
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
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
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
