defmodule Blog.MarkdownTest do
  use ExUnit.Case, async: true

  alias Blog.Markdown

  describe "render/1 and render/2" do
    test "converts markdown to HTML" do
      assert {:ok, [html, []]} = Markdown.render("# Hello World\n\nThis is a test.")

      assert html =~ "<h1"
      assert html =~ "Hello World"
      assert html =~ "<p>"
      assert html =~ "This is a test."
    end

    test "handles markdown with tables" do
      markdown = """
      | Header 1 | Header 2 |
      |----------|----------|
      | Cell 1   | Cell 2   |
      """

      assert {:ok, [html, []]} = Markdown.render(markdown)

      assert html =~ "<table"
      assert html =~ "<thead"
      assert html =~ "<tbody"
    end

    test "handles markdown with strikethrough" do
      assert {:ok, [html, []]} = Markdown.render("~~strikethrough~~")

      assert html =~ "<del>"
    end

    test "processes HTML nodes with custom processor" do
      processor = fn
        {"h1", attrs, children}, acc ->
          {{"h1", [{"class", "custom"} | attrs], children}, ["modified" | acc]}

        other, acc ->
          {other, acc}
      end

      assert {:ok, [html, modifications]} = Markdown.render("# Test", processor)

      assert html =~ ~r/class="custom"/
      assert modifications == ["modified"]
    end

    test "extracts heading information with processor" do
      processor = fn
        {"h" <> level = tag, attrs, children}, acc when level in ["1", "2", "3", "4", "5", "6"] ->
          title = Floki.text({tag, attrs, children})
          {{tag, attrs, children}, [title | acc]}

        other, acc ->
          {other, acc}
      end

      markdown = """
      # Heading One
      ## Heading Two
      ### Heading Three
      """

      assert {:ok, [_html, headings]} = Markdown.render(markdown, processor)
      # Filter out empty strings and only take actual heading text
      headings = headings |> Enum.reject(&(&1 == "")) |> Enum.uniq()
      assert headings == ["Heading One", "Heading Two", "Heading Three"]
    end
  end
end
