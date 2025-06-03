defmodule Blog.Posts.Post do
  @moduledoc "A blog post."

  use Blog.Schema
  alias Blog.Posts.Tag

  schema "posts" do
    field(:title, :string)
    field(:body, :string, default: "")
    field(:raw_body, :string, default: "")

    field(:slug, :string)
    field(:reading_time_minutes, :integer, default: 0)
    field(:is_draft, :boolean, default: true)
    field(:is_redacted, :boolean, default: false)
    field(:published_at, :utc_datetime)
    field(:description, :string)

    embeds_many(:headings, Heading, on_replace: :delete) do
      field(:link, :string)
      field(:title, :string)
      field(:level, :integer)
    end

    field(:rank, :float, virtual: true)

    many_to_many(:tags, Tag,
      join_through: join_schema("posts_tags", {:post_id, :tag_id}),
      on_replace: :delete
    )

    timestamps()
  end

  @spec changeset(t(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, fields() -- [:headings])
    |> generate_body()
    |> generate_headings()
    |> generate_description()
    |> generate_reading_time(attrs)
    |> validate_required([:title, :slug, :description])
    |> preload_put_assoc(attrs, :tags, :tag_ids)
    |> unique_constraint(:slug)
  end

  # TODO: once this gets more complex, we'll split it into its own module
  defp generate_body(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:raw_body)
    |> MDEx.to_html!(extension: [table: true])
    |> render_internal_images()
    |> then(&Ecto.Changeset.put_change(changeset, :body, &1))
  end

  defp generate_headings(changeset) do
    regex = ~r/<h([123456])>[\s\n]*([^<\n]+)[\s\n]*<\/h[123456]>/
    title = Ecto.Changeset.get_field(changeset, :title)
    body = Ecto.Changeset.get_field(changeset, :body)

    normalize = fn heading ->
      heading
      |> String.downcase()
      |> String.replace(~r/\s+/, "-")
    end

    headings =
      regex
      |> Regex.scan(body)
      |> then(&[[nil, "1", title] | &1])
      |> Enum.map(fn [_match, level, title] ->
        id = "heading-" <> normalize.(title)

        %{
          id: id,
          link: "##{id}",
          title: "#{List.duplicate("#", String.to_integer(level))} #{title}",
          level: String.to_integer(level)
        }
      end)

    updated_body =
      Regex.replace(regex, body, fn
        _match, level, title ->
          """
          <h#{level} id="heading-#{normalize.(title)}">
            #{title}
          </h#{level}>
          """
      end)

    changeset
    |> Ecto.Changeset.put_change(:body, updated_body)
    |> Ecto.Changeset.put_embed(:headings, headings)
  end

  defp render_internal_images(html) do
    regex = ~r/src="\.\.\/images\//
    String.replace(html, regex, "src=\"/assets/images/")
  end

  defp generate_description(changeset) do
    description =
      changeset
      |> Ecto.Changeset.get_field(:raw_body)
      |> String.split(~r/\n/)
      |> Enum.take(8)
      |> Enum.join("\n")

    (description <> "\n ... Read more ...")
    |> MDEx.to_html!(extension: [table: true])
    |> then(&Ecto.Changeset.put_change(changeset, :description, &1))
  end

  defp generate_reading_time(changeset, attrs)
       when not is_map_key(attrs, :reading_time_minutes) or is_nil(attrs.reading_time_minutes) do
    technical_words_per_minute = 260

    words =
      changeset
      |> Ecto.Changeset.get_field(:body)
      |> String.split(" ")
      |> Enum.count()

    reading_time_minutes = ceil(words / technical_words_per_minute)

    Ecto.Changeset.put_change(changeset, :reading_time_minutes, reading_time_minutes)
  end

  defp generate_reading_time(changeset, attrs) do
    Ecto.Changeset.put_change(changeset, :reading_time_minutes, attrs.reading_time_minutes)
  end

  @impl EctoUtils.Queryable
  def query(base_query, filters) do
    Enum.reduce(filters, base_query, fn
      {:search, search_term}, query ->
        from post in query,
          join: fts in "posts_fts",
          on: post.id == fts.post_id,
          where: fragment("posts_fts MATCH ?", ^search_term),
          order_by: [asc: fts.rank],
          select_merge: %{rank: fts.rank}

      {key, value}, query ->
        EctoUtils.Queryable.apply_filter(query, key, value)
    end)
  end
end
