defmodule Blog.Schema.FTSTest do
  use ExUnit.Case, async: true

  alias Blog.Schema.FTS

  describe "sanitize_fts_query/1" do
    test "returns nil for empty string" do
      assert FTS.sanitize_fts_query("") == nil
    end

    test "returns nil for whitespace-only string" do
      assert FTS.sanitize_fts_query("   ") == nil
      assert FTS.sanitize_fts_query("\t\n") == nil
    end

    test "returns nil for nil input" do
      assert FTS.sanitize_fts_query(nil) == nil
    end

    test "returns nil for non-string input" do
      assert FTS.sanitize_fts_query(123) == nil
      assert FTS.sanitize_fts_query(%{}) == nil
      assert FTS.sanitize_fts_query([]) == nil
    end

    test "preserves simple word searches" do
      assert FTS.sanitize_fts_query("elixir") == "elixir"
      assert FTS.sanitize_fts_query("hello world") == "hello world"
    end

    test "preserves FTS AND operator" do
      assert FTS.sanitize_fts_query("elixir AND phoenix") == "elixir AND phoenix"
      assert FTS.sanitize_fts_query("foo and bar") == "foo and bar"
    end

    test "preserves FTS OR operator" do
      assert FTS.sanitize_fts_query("elixir OR rust") == "elixir OR rust"
      assert FTS.sanitize_fts_query("foo or bar") == "foo or bar"
    end

    test "preserves FTS NOT operator" do
      assert FTS.sanitize_fts_query("elixir NOT java") == "elixir NOT java"
      assert FTS.sanitize_fts_query("foo not bar") == "foo not bar"
    end

    test "converts single pipe to OR" do
      assert FTS.sanitize_fts_query("foo | bar") == "foo OR bar"
      assert FTS.sanitize_fts_query("elixir|rust") == "elixir OR rust"
    end

    test "converts double pipe to OR" do
      assert FTS.sanitize_fts_query("foo || bar") == "foo OR bar"
      assert FTS.sanitize_fts_query("elixir||rust") == "elixir OR rust"
    end

    test "converts single ampersand to AND" do
      assert FTS.sanitize_fts_query("foo & bar") == "foo AND bar"
      assert FTS.sanitize_fts_query("elixir&phoenix") == "elixir AND phoenix"
    end

    test "converts double ampersand to AND" do
      assert FTS.sanitize_fts_query("foo && bar") == "foo AND bar"
      assert FTS.sanitize_fts_query("elixir&&phoenix") == "elixir AND phoenix"
    end

    test "converts exclamation mark to NOT" do
      assert FTS.sanitize_fts_query("! foo") == "NOT foo"
      assert FTS.sanitize_fts_query("!java") == "NOT java"
    end

    test "preserves quoted phrases" do
      assert FTS.sanitize_fts_query("\"exact phrase\"") == "\"exact phrase\""
      assert FTS.sanitize_fts_query("\"hello world\"") == "\"hello world\""
    end

    test "preserves wildcards" do
      assert FTS.sanitize_fts_query("elixir*") == "elixir*"
      assert FTS.sanitize_fts_query("test*") == "test*"
    end

    test "preserves column filters" do
      assert FTS.sanitize_fts_query("title:elixir") == "title:elixir"
      assert FTS.sanitize_fts_query("name:phoenix") == "name:phoenix"
    end

    test "preserves parentheses for grouping" do
      assert FTS.sanitize_fts_query("(elixir OR rust) AND web") == "(elixir OR rust) AND web"
    end

    test "preserves complete NEAR operator" do
      assert FTS.sanitize_fts_query("NEAR(foo bar)") == "NEAR(foo bar)"
    end

    test "removes problematic characters" do
      assert FTS.sanitize_fts_query("foo~bar") == "foo bar"
      assert FTS.sanitize_fts_query("foo;bar") == "foo bar"
      assert FTS.sanitize_fts_query("foo,bar") == "foo bar"
      assert FTS.sanitize_fts_query("foo?bar") == "foo bar"
      assert FTS.sanitize_fts_query("foo\\bar") == "foo bar"
      assert FTS.sanitize_fts_query("foo=bar") == "foo bar"
      assert FTS.sanitize_fts_query("foo<bar") == "foo bar"
      assert FTS.sanitize_fts_query("foo>bar") == "foo bar"
      assert FTS.sanitize_fts_query("foo[bar]") == "foo bar"
      assert FTS.sanitize_fts_query("foo{bar}") == "foo bar"
    end

    test "removes trailing AND operator" do
      assert FTS.sanitize_fts_query("elixir AND") == "elixir"
      assert FTS.sanitize_fts_query("foo AND ") == "foo"
    end

    test "removes trailing OR operator" do
      assert FTS.sanitize_fts_query("elixir OR") == "elixir"
      assert FTS.sanitize_fts_query("foo OR ") == "foo"
    end

    test "removes trailing NOT operator" do
      assert FTS.sanitize_fts_query("elixir NOT") == "elixir"
      assert FTS.sanitize_fts_query("foo NOT ") == "foo"
    end

    test "removes incomplete NEAR function" do
      assert FTS.sanitize_fts_query("NEAR(") == nil
      assert FTS.sanitize_fts_query("NEAR(foo") == nil
    end

    test "removes incomplete column filter" do
      assert FTS.sanitize_fts_query("title:") == nil
      assert FTS.sanitize_fts_query("name: ") == nil
    end

    test "removes trailing special operators" do
      assert FTS.sanitize_fts_query("elixir+") == "elixir"
      assert FTS.sanitize_fts_query("foo^") == "foo"
      assert FTS.sanitize_fts_query("bar-") == "bar"
      assert FTS.sanitize_fts_query("baz:") == "baz"
      assert FTS.sanitize_fts_query("qux.") == "qux"
    end

    test "returns nil for standalone opening parenthesis" do
      assert FTS.sanitize_fts_query("(") == nil
    end

    test "returns nil for standalone closing parenthesis" do
      assert FTS.sanitize_fts_query(")") == nil
    end

    test "returns nil for standalone AND" do
      assert FTS.sanitize_fts_query("AND") == nil
      assert FTS.sanitize_fts_query("and") == nil
    end

    test "returns nil for standalone OR" do
      assert FTS.sanitize_fts_query("OR") == nil
      assert FTS.sanitize_fts_query("or") == nil
    end

    test "returns nil for standalone NOT" do
      assert FTS.sanitize_fts_query("NOT") == nil
      assert FTS.sanitize_fts_query("not") == nil
    end

    test "cleans up multiple spaces" do
      assert FTS.sanitize_fts_query("foo    bar") == "foo bar"
      assert FTS.sanitize_fts_query("elixir   AND   phoenix") == "elixir AND phoenix"
    end

    test "trims leading and trailing whitespace" do
      assert FTS.sanitize_fts_query("  elixir  ") == "elixir"
      assert FTS.sanitize_fts_query("\telixir\n") == "elixir"
    end

    test "handles complex queries with mixed operators" do
      query = "(elixir OR rust) AND web NOT java"
      assert FTS.sanitize_fts_query(query) == "(elixir OR rust) AND web NOT java"
    end

    test "handles user-friendly operators in complex queries" do
      assert FTS.sanitize_fts_query("(foo | bar) & baz !qux") == "(foo OR bar) AND baz NOT qux"
    end

    test "returns nil when query becomes empty after sanitization" do
      assert FTS.sanitize_fts_query("~~~") == nil
      assert FTS.sanitize_fts_query(";;;") == nil
      assert FTS.sanitize_fts_query("???") == nil
    end
  end

  describe "sanitize_fts_query/2 with prefix option" do
    test "adds wildcard suffix to single word" do
      assert FTS.sanitize_fts_query("hello", prefix: true) == "hello*"
    end

    test "adds wildcard suffix to each word" do
      assert FTS.sanitize_fts_query("hello world", prefix: true) == "hello* world*"
    end

    test "preserves AND operator without wildcard" do
      assert FTS.sanitize_fts_query("hello AND world", prefix: true) == "hello* AND world*"
    end

    test "preserves OR operator without wildcard" do
      assert FTS.sanitize_fts_query("foo OR bar", prefix: true) == "foo* OR bar*"
    end

    test "preserves NOT operator without wildcard" do
      assert FTS.sanitize_fts_query("hello NOT world", prefix: true) == "hello* NOT world*"
    end

    test "preserves NEAR operator without wildcard" do
      assert FTS.sanitize_fts_query("hello NEAR world", prefix: true) == "hello* NEAR world*"
    end

    test "does not double-add wildcards to words already ending with *" do
      assert FTS.sanitize_fts_query("hello*", prefix: true) == "hello*"
      assert FTS.sanitize_fts_query("foo* bar", prefix: true) == "foo* bar*"
    end

    test "returns nil for empty input with prefix option" do
      assert FTS.sanitize_fts_query("", prefix: true) == nil
      assert FTS.sanitize_fts_query(nil, prefix: true) == nil
    end

    test "handles converted operators with prefix" do
      # & gets converted to AND first, then prefix applied
      assert FTS.sanitize_fts_query("foo & bar", prefix: true) == "foo* AND bar*"
    end

    test "prefix false behaves same as no option" do
      assert FTS.sanitize_fts_query("hello world", prefix: false) == "hello world"
      assert FTS.sanitize_fts_query("hello world") == "hello world"
    end
  end

  describe "fts_error?/1" do
    test "returns true for Exqlite.Error with FTS table and MATCH" do
      error = %Exqlite.Error{
        statement: "SELECT * FROM posts_fts WHERE posts_fts MATCH 'query'"
      }

      assert FTS.fts_error?(error) == true
    end

    test "returns true for projects_fts table" do
      error = %Exqlite.Error{
        statement: "SELECT * FROM projects_fts WHERE projects_fts MATCH 'query'"
      }

      assert FTS.fts_error?(error) == true
    end

    test "returns false for non-FTS table with MATCH" do
      error = %Exqlite.Error{
        statement: "SELECT * FROM posts WHERE title MATCH 'query'"
      }

      assert FTS.fts_error?(error) == false
    end

    test "returns false for FTS table without MATCH" do
      error = %Exqlite.Error{
        statement: "SELECT * FROM posts_fts WHERE id = 1"
      }

      assert FTS.fts_error?(error) == false
    end

    test "returns false for non-Exqlite.Error exceptions" do
      error = %RuntimeError{message: "Something went wrong"}
      assert FTS.fts_error?(error) == false
    end

    test "returns false for Exqlite.Error with nil statement" do
      error = %Exqlite.Error{statement: nil}
      assert FTS.fts_error?(error) == false
    end

    test "returns false for non-exception values" do
      assert FTS.fts_error?("not an error") == false
      assert FTS.fts_error?(nil) == false
      assert FTS.fts_error?(123) == false
    end
  end
end
