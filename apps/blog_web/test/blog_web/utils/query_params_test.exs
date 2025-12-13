defmodule BlogWeb.Utils.QueryParamsTest do
  use ExUnit.Case, async: true

  alias BlogWeb.Utils.QueryParams

  doctest QueryParams

  describe "build_url/3" do
    test "builds URL with search query and tags" do
      assert QueryParams.build_url("/posts", "elixir", ["phoenix"]) ==
               "/posts?q=elixir&tags=phoenix"
    end

    test "builds URL with only search query" do
      assert QueryParams.build_url("/posts", "test", []) == "/posts?q=test"
    end

    test "builds URL with only tags" do
      result = QueryParams.build_url("/posts", "", ["web", "api"])
      assert result == "/posts?tags=web%2Capi"
    end

    test "returns base URL when both are empty" do
      assert QueryParams.build_url("/posts", "", []) == "/posts"
    end

    test "handles special characters in search query" do
      result = QueryParams.build_url("/posts", "hello world", [])
      assert result == "/posts?q=hello+world"
    end
  end

  describe "build_params/2" do
    test "builds params with search and tags" do
      assert QueryParams.build_params("elixir", ["phoenix"]) == "q=elixir&tags=phoenix"
    end

    test "builds params with only search" do
      assert QueryParams.build_params("test", []) == "q=test"
    end

    test "builds params with only tags" do
      result = QueryParams.build_params("", ["phoenix", "ecto"])
      assert result == "tags=phoenix%2Cecto"
    end

    test "returns empty string when both are empty" do
      assert QueryParams.build_params("", []) == ""
    end
  end

  describe "clear_search/2" do
    test "clears search but preserves tags" do
      result = QueryParams.clear_search("/posts", ["elixir", "phoenix"])
      assert result == "/posts?tags=elixir%2Cphoenix"
    end

    test "returns base URL when no tags" do
      assert QueryParams.clear_search("/posts", []) == "/posts"
    end
  end

  describe "clear_tags/2" do
    test "clears tags but preserves search" do
      result = QueryParams.clear_tags("/posts", "elixir fts")
      assert result == "/posts?q=elixir+fts"
    end

    test "returns base URL when no search" do
      assert QueryParams.clear_tags("/posts", "") == "/posts"
    end
  end

  describe "toggle_tag/2" do
    test "adds tag when not present" do
      result = QueryParams.toggle_tag(["elixir", "phoenix"], "ecto")
      assert "ecto" in result
      assert "elixir" in result
      assert "phoenix" in result
      assert length(result) == 3
    end

    test "removes tag when present" do
      result = QueryParams.toggle_tag(["elixir", "phoenix"], "elixir")
      assert result == ["phoenix"]
    end

    test "adds tag to empty list" do
      assert QueryParams.toggle_tag([], "elixir") == ["elixir"]
    end

    test "handles list with duplicate tags" do
      # If there are duplicates in the input, ALL occurrences get removed
      result = QueryParams.toggle_tag(["elixir", "elixir", "phoenix"], "elixir")
      # Both "elixir" tags are removed, only "phoenix" remains
      refute "elixir" in result
      assert "phoenix" in result
      assert length(result) == 1
    end
  end
end
