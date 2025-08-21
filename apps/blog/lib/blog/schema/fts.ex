defmodule Blog.Schema.FTS do
  @moduledoc """
  Full-text search utilities for schema modules.

  Provides shared functionality for sanitizing and processing FTS queries
  across different schema modules that support full-text search.
  """

  @doc """
  Sanitizes a full-text search query string to prevent SQLite FTS errors.

  Converts unsupported operators and removes problematic characters while
  preserving valid FTS syntax.

  ## Examples

      iex> Blog.Schema.FTS.sanitize_fts_query("hello & world")
      "hello AND world"

      iex> Blog.Schema.FTS.sanitize_fts_query("")
      nil

      iex> Blog.Schema.FTS.sanitize_fts_query(nil)
      nil

  """
  @spec sanitize_fts_query(binary() | any()) :: binary() | nil
  def sanitize_fts_query(query) when is_binary(query) do
    case String.trim(query) do
      "" ->
        nil

      trimmed ->
        sanitized =
          trimmed
          # Convert unsupported operators to supported equivalents
          # | or || -> OR
          |> String.replace(~r/\s*\|\|?\s*/, " OR ")
          # & or && -> AND
          |> String.replace(~r/\s*\&\&?\s*/, " AND ")
          # ! -> NOT
          |> String.replace(~r/\s*\!\s*/, " NOT ")
          # Remove problematic characters that have no FTS equivalent
          |> String.replace(~r/[\~\;\,\?\\\=\<\>\[\]\{\}]/, " ")
          # Handle trailing operators
          |> String.replace(~r/\s+(AND|OR|NOT)\s*$/i, "")
          # Incomplete NEAR functions
          |> String.replace(~r/NEAR\(\s*$/i, "")
          |> String.replace(~r/NEAR\([^)]*$/i, "")
          # Incomplete column filters
          |> String.replace(~r/\w+:\s*$/, "")
          # Trailing special operators
          |> String.replace(~r/\s+[\+\^\-\:\.]?\s*$/, "")
          # Standalone elements
          |> String.replace(~r/^\s*\(\s*$/, "")
          |> String.replace(~r/^\s*\)\s*$/, "")
          |> String.replace(~r/^\s*(AND|OR|NOT)\s*$/i, "")
          # Clean up multiple spaces
          |> String.replace(~r/\s+/, " ")
          |> String.trim()

        case sanitized do
          "" -> nil
          valid -> valid
        end
    end
  end

  def sanitize_fts_query(_non_binary) do
    nil
  end
end
