defmodule Mix.Tasks.Gen.Post do
  @moduledoc false
  use Mix.Task

  @spec run([String.t()]) :: :ok
  @dialyzer {:nowarn_function, run: 1}
  def run([slug | kv]) when is_binary(slug) do
    title = build_title(slug)
    kv = build_kv(kv)
    post_dir = Blog.Posts.source_path()
    {y, m2, d2, h2, min2, s2} = build_timestamp()

    published_at = "#{y}-#{m2}-#{d2} #{h2}:#{min2}:#{s2}Z"
    filename = "#{y}#{m2}#{d2}#{h2}#{min2}#{s2}_#{slug}.md"

    path = Path.join(post_dir, filename)
    attrs = build_attrs(title, slug, published_at, kv)

    File.write!(path, build_file(attrs))
    IO.puts("Post created at #{Path.relative_to_cwd(path)}")
  end

  def run([]) do
    Mix.raise("Usage: mix gen.post <post_name> <attr=value> ...")
  end

  defp build_title(slug) do
    slug
    |> String.replace("_", " ")
    |> String.replace("-", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp build_timestamp do
    {{y, m, d}, {h, min, s}} = :calendar.universal_time()

    m2 = (m < 10 && "0#{m}") || "#{m}"
    d2 = (d < 10 && "0#{d}") || "#{d}"
    h2 = (h < 10 && "0#{h}") || "#{h}"
    min2 = (min < 10 && "0#{min}") || "#{min}"
    s2 = (s < 10 && "0#{s}") || "#{s}"

    {y, m2, d2, h2, min2, s2}
  end

  defp build_attrs(title, slug, published_at, kv) do
    Enum.map(
      [
        {"title", title},
        {"slug", slug},
        {"is_draft", "false"},
        {"reading_time_minutes", ""},
        {"published_at", published_at},
        {"tags", []}
      ],
      fn {k, v} ->
        {k, Map.get(kv, k, v)}
      end
    )
  end

  defp build_file(attrs) do
    """
    ---
    #{attrs |> Enum.reject(&(elem(&1, 0) == "tags")) |> Enum.map_join("\n", fn {k, v} -> "#{k}: #{v}" end)}
    tags:
    #{attrs |> Enum.find(&(elem(&1, 0) == "tags")) |> elem(1) |> Enum.map_join("\n", fn tag -> "  - #{tag}" end)}
    ---

    Write your post here using Markdown!
    """
  end

  defp build_kv(kv) do
    for kv <- kv, [k, v] = String.split(kv, "="), into: %{} do
      if k == "tags" do
        {k, String.split(v, ",")}
      else
        {k, v}
      end
    end
  end
end
