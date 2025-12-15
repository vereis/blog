defmodule BlogWeb.Components.Aside.Options do
  @moduledoc """
  Options section for the aside containing user preferences.

  Currently includes CRT filter toggle, designed to be extensible for future options.
  """
  use BlogWeb, :html

  alias BlogWeb.Components.Aside
  alias BlogWeb.Components.Checkbox

  @doc """
  Renders the options section with CRT filter toggle.

  ## Attributes

    * `id` - Unique DOM ID for the aside section (default: "options")

  ## Slots

    * `inner_block` - Optional slot for additional options

  ## Examples

      <Options.options />

      <Options.options id="custom-options">
        <p>Additional options can go here</p>
      </Options.options>
  """
  attr :id, :string, default: "options"
  slot :inner_block

  def options(assigns) do
    ~H"""
    <Aside.aside_section title="Options" id={@id}>
      <Checkbox.checkbox
        id="crt-filter-toggle"
        storage_key="crtFilter"
        body_class="crt-filter"
        label="CRT Filter"
      />
      {render_slot(@inner_block)}
    </Aside.aside_section>
    """
  end
end
