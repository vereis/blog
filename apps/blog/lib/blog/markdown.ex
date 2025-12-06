defmodule Blog.Markdown do
  @moduledoc "Utilities for converting markdown to HTML"

  @markdown_opts [
    extension: [
      table: true,
      strikethrough: true,
      underline: true,
      shortcodes: true
    ],
    parse: [
      smart: true
    ],
    render: [
      unsafe_: true
    ]
  ]

  @doc """
  Renders the given markdown string to HTML.

  Takes an optional processor function that is called for each HTML node, and
  can be used to modify the HTML output, as well as to return arbitrarily
  many additional values collected during processing.

  The processor function is called with two arguments: the current HTML node,
  and an accumulator value. It must return a tuple with the modified HTML node
  and the updated accumulator.

  Examples

      iex> Blog.Markdown.render("# Hello World\\n\\nThis is a test.")
      {:ok, ["<h1>Hello World</h1>\\n<p>This is a test.</p>\\n", []]}

      iex> processor = fn
      ...>   {"h1", attrs, children}, acc ->
      ...>     {{"h1", [{"class", "custom"} | attrs], children}, ["modified" | acc]}
      ...>
      ...>   other, acc ->
      ...>     {other, acc}
      ...> end
      iex> Blog.Markdown.render("# Test", processor)
      {:ok, ["<h1 class=\\"custom\\">Test</h1>\\n", ["modified"]]}

  """
  @spec render(String.t(), (any(), any() -> {any(), any()})) ::
          {:ok, list()} | {:error, String.t()}
  def render(markdown, processor \\ fn node, acc -> {node, acc} end)
      when is_binary(markdown) and is_function(processor, 2) do
    with {:ok, ast} <- MDEx.parse_document(markdown, @markdown_opts),
         {:ok, html} <- MDEx.to_html(ast, @markdown_opts) do
      postprocess(html, processor)
    end
  end

  defp postprocess(html, processor) do
    with {:ok, ast} <- Floki.parse_document(html) do
      {modified_html, acc} = Floki.traverse_and_update(ast, [], processor)

      {:ok, [Floki.raw_html(modified_html), maybe_reverse_acc(acc)]}
    end
  rescue
    error ->
      {:error, Exception.message(error)}
  end

  defp maybe_reverse_acc(acc) when is_map(acc) do
    Map.new(acc, fn
      {key, value} when is_list(value) -> {key, Enum.reverse(value)}
      {key, value} -> {key, value}
    end)
  end

  defp maybe_reverse_acc(acc) when is_list(acc) do
    Enum.reverse(acc)
  end

  defp maybe_reverse_acc(acc) do
    acc
  end
end
