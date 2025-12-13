defmodule BlogWeb.Components.SearchTest do
  use ExUnit.Case, async: true

  alias BlogWeb.Components.Search

  describe "query_from_params/2" do
    test "extracts query from params with default key" do
      assert Search.query_from_params(%{"q" => "elixir fts"}) == "elixir fts"
    end

    test "trims whitespace from query" do
      assert Search.query_from_params(%{"q" => "  phoenix  "}) == "phoenix"
    end

    test "returns empty string when key not present" do
      assert Search.query_from_params(%{}) == ""
    end

    test "extracts query with custom key" do
      assert Search.query_from_params(%{"search" => "test"}, "search") == "test"
    end

    test "handles nil values" do
      assert Search.query_from_params(%{"q" => nil}) == ""
    end
  end

  describe "build_query_params/2" do
    test "builds query params with search and tags" do
      assert Search.build_query_params("elixir", ["phoenix"]) == "q=elixir&tags=phoenix"
    end

    test "builds query params with only tags" do
      result = Search.build_query_params("", ["phoenix", "ecto"])
      assert result == "tags=phoenix%2Cecto"
    end

    test "builds query params with only search" do
      assert Search.build_query_params("test", []) == "q=test"
    end

    test "returns empty string when both are empty" do
      assert Search.build_query_params("", []) == ""
    end

    test "properly encodes special characters in search query" do
      query = "phoenix && (web || api)"
      result = Search.build_query_params(query, [])
      decoded = URI.decode_query(result)
      assert decoded["q"] == query
    end

    test "properly encodes quotes in search query" do
      query = ~s["exact phrase" AND keyword]
      result = Search.build_query_params(query, [])
      decoded = URI.decode_query(result)
      assert decoded["q"] == query
    end

    test "properly encodes ampersands in search query" do
      query = "one & two"
      result = Search.build_query_params(query, [])
      decoded = URI.decode_query(result)
      assert decoded["q"] == query
    end

    test "properly encodes plus signs in search query" do
      query = "C++"
      result = Search.build_query_params(query, [])
      decoded = URI.decode_query(result)
      assert decoded["q"] == query
    end

    test "handles complex FTS query with operators and parens" do
      query = "(Distributed && Elixir) OR Fun"
      result = Search.build_query_params(query, ["tech", "programming"])
      decoded = URI.decode_query(result)
      assert decoded["q"] == query
      assert decoded["tags"] == "tech,programming"
    end
  end
end
