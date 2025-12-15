defmodule BlogWeb.Components.OptionsTest do
  use BlogWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias BlogWeb.Components.Aside.Options

  describe "options/1" do
    test "renders options section with title" do
      assigns = %{}

      html = render_component(&Options.options/1, assigns)

      assert html =~ "Options"
      assert html =~ "aside-section"
    end

    test "renders CRT filter checkbox" do
      assigns = %{}

      html = render_component(&Options.options/1, assigns)

      assert html =~ "crt-filter-toggle"
      assert html =~ "CRT Filter"
      assert html =~ ~s(type="checkbox")
    end

    test "uses default id when not provided" do
      assigns = %{}

      html = render_component(&Options.options/1, assigns)

      assert html =~ ~s(id="options")
    end

    test "uses custom id when provided" do
      assigns = %{id: "custom-options"}

      html = render_component(&Options.options/1, assigns)

      assert html =~ ~s(id="custom-options")
    end

    test "renders without inner_block content when not provided" do
      assigns = %{}

      html = render_component(&Options.options/1, assigns)

      assert html =~ "CRT Filter"
      refute html =~ "Extra options"
    end
  end
end
