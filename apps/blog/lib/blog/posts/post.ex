defmodule Blog.Posts.Post do
  @moduledoc false
  use Blog.Schema

  use Blog.Resource,
    source_dir: "priv/posts",
    preprocess: &Blog.Tags.label_to_id/1,
    import: &Blog.Posts.upsert_post/1

  import Blog.Utils.Guards

  alias Blog.Assets
  alias Blog.Assets.Asset
  alias Blog.Markdown

  @castable_fields [:title, :raw_body, :slug, :is_draft, :published_at]
  @slug_format ~r/^[a-z0-9_-]+$/
  @reading_speed_wpm 260

  schema "posts" do
    field :title, :string
    field :body, :string
    field :excerpt, :string
    field :raw_body, :string
    field :slug, :string
    field :reading_time_minutes, :integer
    field :is_draft, :boolean, default: false
    field :published_at, :utc_datetime

    many_to_many :tags, Blog.Tags.Tag,
      join_through: join_schema("posts_tags", {:post_id, :tag_id}),
      on_replace: :delete

    embeds_many :headings, Heading, primary_key: false, on_replace: :delete do
      field :link, :string
      field :title, :string
      field :level, :integer
    end

    timestamps()
  end

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t(t())
  def changeset(post, attrs) do
    slug_error = "must be lowercase alphanumeric with hyphens or underscores only"

    post
    |> cast(attrs, @castable_fields)
    |> validate_required([:title, :raw_body, :slug])
    |> validate_format(:slug, @slug_format, message: slug_error)
    |> unique_constraint(:slug)
    |> preload_put_assoc(attrs, :tags, :tag_ids)
    |> process_markdown()
  end

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {:tags, tags}, query ->
        from post in query,
          join: t in assoc(post, :tags),
          where: t.label in ^tags,
          distinct: true

      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end

  @impl Blog.Resource
  def handle_import(%Blog.Resource{content: content}) do
    # Split only on the opening --- and the first closing ---
    # This allows --- to be used as horizontal rules in the markdown body
    with [_front, metadata_yaml, raw_body] <- String.split(content, ~r/^---\n/m, parts: 3),
         {:ok, metadata} <- YamlElixir.read_from_string(metadata_yaml) do
      metadata
      |> Map.take(Enum.map(@castable_fields, &Atom.to_string/1))
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      |> Map.merge(%{raw_body: raw_body, tags: Map.get(metadata, "tags", [])})
    end
  end

  defp calculate_reading_time(raw_body) do
    word_count =
      raw_body
      |> String.split(~r/\s+/)
      |> Enum.reject(&(&1 == ""))
      |> length()

    max(1, (word_count / @reading_speed_wpm) |> Float.ceil() |> trunc())
  end

  defp process_markdown(changeset) when not valid?(changeset) do
    changeset
  end

  defp process_markdown(changeset) when not changes?(changeset, :raw_body) do
    changeset
  end

  defp process_markdown(changeset) do
    raw_body = get_change(changeset, :raw_body)
    title = get_field(changeset, :title)

    case Markdown.render(raw_body, &process_html/2) do
      {:ok, [html, %{headings: headings, excerpt: excerpt}]} ->
        reading_time = calculate_reading_time(raw_body)

        # Always include title as the top-level heading
        title_heading = %{
          level: 1,
          title: title,
          link: slugify(title)
        }

        all_headings = [title_heading | headings]

        changeset
        |> put_change(:body, html)
        |> put_change(:excerpt, excerpt)
        |> put_change(:reading_time_minutes, reading_time)
        |> put_embed(:headings, all_headings)

      {:error, reason} ->
        add_error(changeset, :raw_body, reason)
    end
  end

  # NOTE: Initialize accumulator on first node if still using default empty list
  defp process_html(node, []) do
    process_html(node, %{headings: [], excerpt: "", excerpt_stopped: false, excerpt_count: 0})
  end

  # NOTE: Make sure all headings have unique IDs we can link to.
  # NOTE: Side effect: Accumulate headings so that we can build a list of headers to store in the DB.
  defp process_html({"h" <> level_str = tag, attrs, children}, acc)
       when level_str in ["1", "2", "3", "4", "5", "6"] and is_map(acc) do
    level = String.to_integer(level_str)
    title = Floki.text({tag, attrs, children})
    link = slugify(title)

    heading = %{
      level: level,
      title: title,
      link: link
    }

    # Stop excerpt collection at h2+ if we have paragraphs
    new_stopped =
      if level > 1 and acc.excerpt != "",
        do: true,
        else: acc.excerpt_stopped

    {{tag, [{"id", link} | attrs], children}, %{acc | headings: [heading | acc.headings], excerpt_stopped: new_stopped}}
  end

  # NOTE: Collect paragraphs for excerpt (first 3, until stopped)
  defp process_html({"p", _, _} = node, %{excerpt: excerpt, excerpt_stopped: false, excerpt_count: count} = acc)
       when count < 3 do
    paragraph_html = Floki.raw_html(node)
    {node, %{acc | excerpt: excerpt <> paragraph_html, excerpt_count: count + 1}}
  end

  # NOTE: Stop excerpt collection at block elements if we have paragraphs
  defp process_html({tag, _, _} = node, %{excerpt: excerpt, excerpt_stopped: false} = acc)
       when tag in ["ul", "ol", "table", "blockquote", "pre", "hr"] and excerpt != "" do
    {node, %{acc | excerpt_stopped: true}}
  end

  # NOTE: Wrap images in links to the full-size image and add LQIP styles for optimized loading.
  defp process_html({"img", attrs, children}, acc) do
    src = [{"img", attrs, children}] |> Floki.attribute("src") |> List.first()

    {updated_attrs, href} =
      with true <- Regex.match?(~r/\/assets\//, src),
           false <- Regex.match?(~r/^https?:\/\//, src),
           name = (src |> Path.basename() |> Path.rootname()) <> ".webp",
           %Asset{} = asset <- Assets.get_asset(name: name) do
        new_src = "/assets/images/#{asset.name}"
        lqip_style = if asset.lqip_hash, do: "--lqip:#{asset.lqip_hash}", else: ""

        updated =
          attrs
          |> List.keystore("src", 0, {"src", new_src})
          |> List.keystore("style", 0, {"style", lqip_style})
          |> List.keystore("width", 0, {"width", to_string(asset.width)})
          |> List.keystore("height", 0, {"height", to_string(asset.height)})

        {updated, new_src}
      else
        _noop? -> {attrs, src}
      end

    link_attrs = [
      {"href", href},
      {"title", "View full size"},
      {"target", "_blank"},
      {"rel", "noopener"}
    ]

    {{"a", link_attrs, [{"img", updated_attrs, children}]}, acc}
  end

  defp process_html(other, acc) do
    {other, acc}
  end

  @doc false
  @spec slugify(String.t(), keyword()) :: String.t()
  def slugify(text, opts \\ []) do
    separator = Keyword.get(opts, :separator, "-")

    text
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/\s+/, separator)
    |> String.trim(separator)
  end
end
