defmodule Blog.Schema.FTS do
  @moduledoc """
  Full-text search utilities for schema modules.

  Provides shared functionality for sanitizing and processing FTS queries
  across different schema modules that support full-text search.
  """

  @fts_columns ~w(title name description tags raw_body excerpt)
  @incomplete_column_patterns Enum.map(@fts_columns, &Regex.compile!("^\\s*#{&1}\\s*:\\s*$", [:caseless]))

  # Pre-compiled sanitization patterns
  @pipe_to_or ~r/\s*\|\|?\s*/
  @ampersand_to_and ~r/\s*\&\&?\s*/
  @exclamation_to_not ~r/\s*\!\s*/
  @problematic_chars ~r/[\~\;\,\?\\\=\<\>\[\]\{\}]/
  @trailing_operators ~r/\s+(AND|OR|NOT)\s*$/i
  @incomplete_near_start ~r/NEAR\(\s*$/i
  @incomplete_near_partial ~r/NEAR\([^)]*$/i
  @trailing_colon ~r/:\s*$/
  @trailing_special ~r/[\+\^\-\:\.]?\s*$/
  @standalone_open_paren ~r/^\s*\(\s*$/
  @standalone_close_paren ~r/^\s*\)\s*$/
  @standalone_operators ~r/^\s*(AND|OR|NOT)\s*$/i
  @multiple_spaces ~r/\s+/

  @doc """
  Sanitizes a full-text search query string to prevent SQLite FTS errors.

  Converts unsupported operators and removes problematic characters while
  preserving valid FTS syntax.

  When `prefix: true` is passed, appends `*` to each word to enable prefix
  matching (e.g., "hel" matches "hello", "help", etc.).

  ## Examples

      iex> Blog.Schema.FTS.sanitize_fts_query("hello & world")
      "hello AND world"

      iex> Blog.Schema.FTS.sanitize_fts_query("hel", prefix: true)
      "hel*"

      iex> Blog.Schema.FTS.sanitize_fts_query("hello world", prefix: true)
      "hello* world*"

      iex> Blog.Schema.FTS.sanitize_fts_query("")
      nil

      iex> Blog.Schema.FTS.sanitize_fts_query(nil)
      nil

  """
  @spec sanitize_fts_query(binary() | any(), keyword()) :: binary() | nil
  def sanitize_fts_query(query, opts \\ [])

  def sanitize_fts_query(query, opts) when is_binary(query) do
    trimmed = String.trim(query)

    cond do
      trimmed == "" ->
        nil

      Enum.any?(@incomplete_column_patterns, &String.match?(trimmed, &1)) ->
        nil

      true ->
        sanitized = do_sanitize(trimmed)

        if Keyword.get(opts, :prefix, false) do
          add_prefix_wildcards(sanitized)
        else
          sanitized
        end
    end
  end

  def sanitize_fts_query(_non_binary, _opts), do: nil

  defp do_sanitize(query) do
    sanitized =
      query
      |> String.replace(@pipe_to_or, " OR ")
      |> String.replace(@ampersand_to_and, " AND ")
      |> String.replace(@exclamation_to_not, " NOT ")
      |> String.replace(@problematic_chars, " ")
      |> String.replace(@trailing_operators, "")
      |> String.replace(@incomplete_near_start, "")
      |> String.replace(@incomplete_near_partial, "")
      |> String.replace(@trailing_colon, "")
      |> String.replace(@trailing_special, "")
      |> String.replace(@standalone_open_paren, "")
      |> String.replace(@standalone_close_paren, "")
      |> String.replace(@standalone_operators, "")
      |> String.replace(@multiple_spaces, " ")
      |> String.trim()

    if sanitized == "", do: nil, else: sanitized
  end

  # Adds `*` suffix to each word for prefix matching, preserving operators
  defp add_prefix_wildcards(nil), do: nil

  defp add_prefix_wildcards(query) do
    query
    |> String.split(~r/\s+/)
    |> Enum.map_join(" ", fn word ->
      # Don't add wildcards to FTS operators or words already ending with *
      if word in ~w(AND OR NOT NEAR) or String.ends_with?(word, "*") do
        word
      else
        word <> "*"
      end
    end)
  end

  @doc """
  Detects if an exception is an FTS-related error from Exqlite.

  This helper allows context modules to gracefully handle FTS query errors
  without duplicating error detection logic.

  ## Examples

      iex> error = %Exqlite.Error{statement: "SELECT * FROM posts_fts WHERE posts_fts MATCH 'bad'"}
      iex> Blog.Schema.FTS.fts_error?(error)
      true

      iex> error = %Exqlite.Error{statement: "SELECT * FROM posts"}
      iex> Blog.Schema.FTS.fts_error?(error)
      false

  """
  @spec fts_error?(Exception.t()) :: boolean()
  def fts_error?(%Exqlite.Error{statement: statement}) when is_binary(statement) do
    String.contains?(statement, "_fts") and String.contains?(statement, "MATCH")
  end

  def fts_error?(_exception), do: false
end
