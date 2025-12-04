defmodule Blog.Posts.Post do
  @moduledoc false
  use Blog.Schema

  use Blog.Resource,
    source_dir: "priv/posts",
    import: &Blog.Posts.upsert_post/1

  alias Blog.Markdown

  @castable_fields [:title, :raw_body, :slug, :is_draft, :published_at]
  @slug_format ~r/^[a-z0-9_-]+$/
  @reading_speed_wpm 260

  defguardp valid?(changeset)
            when is_struct(changeset, Ecto.Changeset) and changeset.valid? == true

  defguardp changes?(changeset, field)
            when is_struct(changeset, Ecto.Changeset) and is_map_key(changeset.changes, field)

  schema "posts" do
    field :title, :string
    field :body, :string
    field :raw_body, :string
    field :slug, :string
    field :reading_time_minutes, :integer
    field :is_draft, :boolean, default: false
    field :published_at, :utc_datetime
    field :hash, :string

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
    post
    |> cast(attrs, @castable_fields)
    |> validate_required([:title, :raw_body, :slug])
    |> validate_format(:slug, @slug_format, message: "must be lowercase alphanumeric with hyphens or underscores only")
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
    with [_front, metadata_yaml, raw_body] <- String.split(content, "---\n", parts: 3),
         {:ok, metadata} <- YamlElixir.read_from_string(metadata_yaml) do
      metadata
      |> Map.take(Enum.map(@castable_fields, &Atom.to_string/1))
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      |> Map.put(:raw_body, String.trim(raw_body))
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

    case Markdown.render(raw_body, &process_html/2) do
      {:ok, [html, headings]} ->
        reading_time = calculate_reading_time(raw_body)

        changeset
        |> put_change(:body, html)
        |> put_change(:reading_time_minutes, reading_time)
        |> put_embed(:headings, headings)

      {:error, reason} ->
        add_error(changeset, :raw_body, reason)
    end
  end

  # NOTE: Make sure all headings have unique IDs we can link to.
  # NOTE: Side effect: Accumulate headings so that we can build a list of headers to store in the DB.
  defp process_html({"h" <> level_str = tag, attrs, children}, acc) do
    level = String.to_integer(level_str)
    title = Floki.text({tag, attrs, children})
    link = slugify(title)

    heading = %{
      level: level,
      title: title,
      link: link
    }

    {{tag, [{"id", link} | attrs], children}, [heading | acc]}
  end

  # NOTE: Wrap images in links so that when clicked, they open the full-size image in a new tab.
  defp process_html({"img", attrs, children}, acc) do
    src = [{"img", attrs, children}] |> Floki.attribute("src") |> List.first()

    link_attrs = [
      {"href", src},
      {"title", "View full size"},
      {"target", "_blank"},
      {"rel", "noopener"}
    ]

    {{"a", link_attrs, [{"img", attrs, children}]}, acc}
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
