defmodule BlogWeb.Components.TableOfContentsTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest

  alias BlogWeb.Components.Aside.Toc

  describe "Toc.toc/1" do
    test "renders empty state when no headings provided" do
      html = render_component(&Toc.toc/1, %{headings: []})

      assert html =~ "No headings available"
      refute html =~ "toc-list"
    end

    test "renders table of contents with headings" do
      headings = [
        %{title: "Introduction", link: "introduction", level: 1},
        %{title: "Getting Started", link: "getting-started", level: 2},
        %{title: "Conclusion", link: "conclusion", level: 1}
      ]

      html = render_component(&Toc.toc/1, %{headings: headings})

      assert html =~ "Introduction"
      assert html =~ "Getting Started"
      assert html =~ "Conclusion"
      assert html =~ ~s(class="toc-list")
    end

    test "renders correct anchor links" do
      headings = [
        %{title: "Introduction", link: "introduction", level: 1},
        %{title: "Getting Started", link: "getting-started", level: 2}
      ]

      html = render_component(&Toc.toc/1, %{headings: headings})

      assert html =~ ~s(href="#introduction")
      assert html =~ ~s(href="#getting-started")
    end

    test "includes data-heading-id attributes for JS targeting" do
      headings = [
        %{title: "Introduction", link: "introduction", level: 1},
        %{title: "Getting Started", link: "getting-started", level: 2}
      ]

      html = render_component(&Toc.toc/1, %{headings: headings})

      assert html =~ ~s(data-heading-id="introduction")
      assert html =~ ~s(data-heading-id="getting-started")
    end

    test "includes heading level data attributes" do
      headings = [
        %{title: "Introduction", link: "introduction", level: 1},
        %{title: "Getting Started", link: "getting-started", level: 2}
      ]

      html = render_component(&Toc.toc/1, %{headings: headings})

      assert html =~ ~s(data-level="1")
      assert html =~ ~s(data-level="2")
    end

    test "uses custom id when provided" do
      headings = [%{title: "Test", link: "test", level: 1}]
      html = render_component(&Toc.toc/1, %{headings: headings, id: "custom-toc"})

      assert html =~ ~s(id="custom-toc")
    end

    test "uses default id when not provided" do
      headings = [%{title: "Test", link: "test", level: 1}]
      html = render_component(&Toc.toc/1, %{headings: headings})

      assert html =~ ~s(id="toc")
    end

    test "renders semantic HTML with nav and aria-label" do
      headings = [%{title: "Test", link: "test", level: 1}]
      html = render_component(&Toc.toc/1, %{headings: headings})

      assert html =~ ~s(<nav)
      assert html =~ ~s(aria-label="Table of contents")
    end

    test "renders ordered list structure" do
      headings = [
        %{title: "First", link: "first", level: 1},
        %{title: "Second", link: "second", level: 1}
      ]

      html = render_component(&Toc.toc/1, %{headings: headings})

      assert html =~ "<ol"
      assert html =~ "<li"
      assert html =~ "toc-item"
    end
  end
end
