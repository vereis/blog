defmodule BlogWeb.Components.ViewersTest do
  use BlogWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias BlogWeb.Components.Viewers

  describe "counts/1" do
    test "renders viewer counts with default id" do
      assigns = %{site_count: 10, page_count: 3}

      html = render_component(&Viewers.counts/1, assigns)

      assert html =~ "viewer-counts"
      assert html =~ "Viewers"
      assert html =~ "Site-wide:"
      assert html =~ "10"
      assert html =~ "This page:"
      assert html =~ "3"
    end

    test "renders viewer counts with custom id" do
      assigns = %{site_count: 5, page_count: 2, id: "custom-viewers"}

      html = render_component(&Viewers.counts/1, assigns)

      assert html =~ ~s(id="custom-viewers")
      assert html =~ "5"
      assert html =~ "2"
    end

    test "renders zero counts correctly" do
      assigns = %{site_count: 0, page_count: 0}

      html = render_component(&Viewers.counts/1, assigns)

      assert html =~ "Site-wide:"
      assert html =~ "0"
      assert html =~ "This page:"
    end

    test "renders large viewer counts" do
      assigns = %{site_count: 1_234_567, page_count: 999_999}

      html = render_component(&Viewers.counts/1, assigns)

      # Elixir will render integers with underscore separators as plain numbers
      assert html =~ "1234567"
      assert html =~ "999999"
    end

    test "includes proper ARIA labels" do
      assigns = %{site_count: 1, page_count: 1}

      html = render_component(&Viewers.counts/1, assigns)

      assert html =~ ~s(aria-label="Viewer Counts")
    end

    test "includes viewer bullet points" do
      assigns = %{site_count: 5, page_count: 3}

      html = render_component(&Viewers.counts/1, assigns)

      assert html =~ "viewer-bullet"
    end

    test "includes proper CSS classes for styling" do
      assigns = %{site_count: 10, page_count: 5}

      html = render_component(&Viewers.counts/1, assigns)

      assert html =~ "viewer-counts"
      assert html =~ "viewer-stat"
      assert html =~ "viewer-label"
      assert html =~ "viewer-count"
    end
  end
end
