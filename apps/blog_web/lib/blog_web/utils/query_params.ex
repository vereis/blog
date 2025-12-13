defmodule BlogWeb.Utils.QueryParams do
  @moduledoc """
  Utilities for building filter URLs with search queries and tags.

  This module provides a centralized location for all URL query parameter
  building logic used by the search and tag filter components.
  """

  @doc """
  Builds a complete URL with search query and selected tags.

  Returns the base URL if both search and tags are empty, otherwise
  appends the appropriate query parameters.

  ## Examples

      iex> BlogWeb.Utils.QueryParams.build_url("/posts", "elixir", ["phoenix"])
      "/posts?q=elixir&tags=phoenix"

      iex> BlogWeb.Utils.QueryParams.build_url("/posts", "", [])
      "/posts"

      iex> BlogWeb.Utils.QueryParams.build_url("/posts", "test", [])
      "/posts?q=test"

      iex> BlogWeb.Utils.QueryParams.build_url("/posts", "", ["web", "api"])
      "/posts?tags=web%2Capi"

  """
  def build_url(base_url, search_query, selected_tags) do
    params = build_params(search_query, selected_tags)

    if params == "" do
      base_url
    else
      "#{base_url}?#{params}"
    end
  end

  @doc """
  Builds query parameters string combining search and tags for URL.

  Returns an empty string if both search and tags are empty.

  ## Examples

      iex> BlogWeb.Utils.QueryParams.build_params("elixir", ["phoenix"])
      "q=elixir&tags=phoenix"

      iex> BlogWeb.Utils.QueryParams.build_params("", ["phoenix", "ecto"])
      "tags=phoenix%2Cecto"

      iex> BlogWeb.Utils.QueryParams.build_params("test", [])
      "q=test"

      iex> BlogWeb.Utils.QueryParams.build_params("", [])
      ""

  """
  def build_params(search_query, selected_tags) do
    params = %{}

    params =
      if search_query == "" do
        params
      else
        Map.put(params, "q", search_query)
      end

    params =
      if selected_tags == [] do
        params
      else
        Map.put(params, "tags", Enum.join(selected_tags, ","))
      end

    URI.encode_query(params)
  end

  @doc """
  Builds a URL with search query cleared, preserving selected tags.

  ## Examples

      iex> BlogWeb.Utils.QueryParams.clear_search("/posts", ["elixir", "phoenix"])
      "/posts?tags=elixir%2Cphoenix"

      iex> BlogWeb.Utils.QueryParams.clear_search("/posts", [])
      "/posts"

  """
  def clear_search(base_url, selected_tags) do
    build_url(base_url, "", selected_tags)
  end

  @doc """
  Builds a URL with tags cleared, preserving search query.

  ## Examples

      iex> BlogWeb.Utils.QueryParams.clear_tags("/posts", "elixir fts")
      "/posts?q=elixir+fts"

      iex> BlogWeb.Utils.QueryParams.clear_tags("/posts", "")
      "/posts"

  """
  def clear_tags(base_url, search_query) do
    build_url(base_url, search_query, [])
  end

  @doc """
  Toggles a tag in the selected tags list.

  If the tag is present, it's removed. If it's absent, it's added.
  Order is not preserved as filtering is commutative.

  ## Examples

      iex> result = BlogWeb.Utils.QueryParams.toggle_tag(["elixir", "phoenix"], "ecto")
      iex> Enum.sort(result)
      ["ecto", "elixir", "phoenix"]

      iex> BlogWeb.Utils.QueryParams.toggle_tag(["elixir", "phoenix"], "elixir")
      ["phoenix"]

      iex> BlogWeb.Utils.QueryParams.toggle_tag([], "elixir")
      ["elixir"]

  """
  def toggle_tag(selected_tags, tag) do
    # Traverse selected tags in O(n), if we find the tag during enumeration,
    # we drop it from the acc, if we never find it, we add it at the end.
    #
    # NOTE: This does not preserve the order of tags, but currently filtering
    # is commutative so order does not matter. For preserving order we'd need
    # to eat another enumeration to reverse the list.
    acc = {false, []}

    selected_tags
    |> Enum.reduce(acc, fn t, {found, acc} ->
      (t == tag && {true, acc}) || {found, [t | acc]}
    end)
    |> then(fn {found?, acc} -> (found? && acc) || [tag | acc] end)
  end
end
