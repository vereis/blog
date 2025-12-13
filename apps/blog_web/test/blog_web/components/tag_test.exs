defmodule BlogWeb.Components.TagTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest

  alias BlogWeb.Components.Tag

  describe "labels_from_params/1" do
    test "parses comma-separated tags from params" do
      assert Tag.labels_from_params(%{"tags" => "elixir,phoenix"}) == ["elixir", "phoenix"]
    end

    test "trims whitespace from tag labels" do
      assert Tag.labels_from_params(%{"tags" => "elixir, phoenix , ecto"}) == [
               "elixir",
               "phoenix",
               "ecto"
             ]
    end

    test "filters out empty strings" do
      assert Tag.labels_from_params(%{"tags" => "elixir,,phoenix,"}) == ["elixir", "phoenix"]
    end

    test "returns empty list when tags param is missing" do
      assert Tag.labels_from_params(%{}) == []
    end

    test "handles single tag" do
      assert Tag.labels_from_params(%{"tags" => "elixir"}) == ["elixir"]
    end
  end

  describe "tag_label/1" do
    test "extracts label from Tag struct" do
      tag = %Blog.Tags.Tag{label: "elixir"}
      assert Tag.tag_label(tag) == "elixir"
    end

    test "returns string label as-is" do
      assert Tag.tag_label("phoenix") == "phoenix"
    end
  end

  describe "filter/1" do
    test "renders inline empty state with accessibility when no tags available" do
      html =
        render_component(&Tag.filter/1, %{
          tags: [],
          base_url: "/posts",
          selected_tags: []
        })

      assert html =~ ~s(class="empty-state-inline")
      assert html =~ ~s(role="status")
      assert html =~ "No tags available"
    end
  end

  describe "tag_filter_href/3" do
    test "appends tag when not in selected list" do
      assert Tag.tag_filter_href("/posts", "elixir", []) == "/posts?tags=elixir"
    end

    test "appends tag to existing selection" do
      result = Tag.tag_filter_href("/posts", "liveview", ["elixir", "phoenix"])
      assert String.starts_with?(result, "/posts?tags=")

      # Extract tags from URL and verify all three are present
      [_base, query] = String.split(result, "?tags=")
      tags = query |> URI.decode() |> String.split(",") |> MapSet.new()

      assert MapSet.equal?(tags, MapSet.new(["liveview", "elixir", "phoenix"]))
    end

    test "removes tag when in selected list" do
      assert Tag.tag_filter_href("/posts", "elixir", ["elixir", "phoenix"]) ==
               "/posts?tags=phoenix"
    end

    test "returns base_url with empty tags param when removing last tag" do
      assert Tag.tag_filter_href("/posts", "elixir", ["elixir"]) == "/posts?tags="
    end

    test "works with Tag struct" do
      tag = %Blog.Tags.Tag{label: "elixir"}
      assert Tag.tag_filter_href("/posts", tag, []) == "/posts?tags=elixir"
    end
  end
end
