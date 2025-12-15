defmodule BlogWeb.Components.CheckboxTest do
  use BlogWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias BlogWeb.Components.Checkbox

  describe "checkbox/1" do
    test "renders checkbox with label" do
      assigns = %{
        id: "test-checkbox",
        storage_key: "testKey",
        body_class: "test-class",
        label: "Test Label"
      }

      html = render_component(&Checkbox.checkbox/1, assigns)

      assert html =~ "test-checkbox"
      assert html =~ "Test Label"
      assert html =~ ~s(type="checkbox")
    end

    test "renders with correct data attributes" do
      assigns = %{
        id: "crt-filter-toggle",
        storage_key: "crtFilter",
        body_class: "crt-filter",
        label: "CRT Filter"
      }

      html = render_component(&Checkbox.checkbox/1, assigns)

      assert html =~ ~s(data-storage-key="crtFilter")
      assert html =~ ~s(data-body-class="crt-filter")
    end

    test "renders checked when checked is true" do
      assigns = %{
        id: "test-checkbox",
        storage_key: "testKey",
        body_class: "test-class",
        label: "Test Label",
        checked: true
      }

      html = render_component(&Checkbox.checkbox/1, assigns)

      assert html =~ "checked"
    end

    test "renders unchecked by default" do
      assigns = %{
        id: "test-checkbox",
        storage_key: "testKey",
        body_class: "test-class",
        label: "Test Label"
      }

      html = render_component(&Checkbox.checkbox/1, assigns)

      refute html =~ "checked"
    end

    test "includes colocated JS hook" do
      assigns = %{
        id: "test-checkbox",
        storage_key: "testKey",
        body_class: "test-class",
        label: "Test Label"
      }

      html = render_component(&Checkbox.checkbox/1, assigns)

      assert html =~ "phx-hook"
      assert html =~ ".CheckboxToggle"
    end
  end
end
