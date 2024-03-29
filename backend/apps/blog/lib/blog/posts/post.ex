defmodule Blog.Posts.Post do
  @moduledoc "A blog post."

  use Blog.Schema

  alias Blog.Posts.Tag

  schema "posts" do
    field :title, :string
    field :body, :string, default: ""
    field :raw_body, :string, default: ""

    field :slug, :string
    field :reading_time_minutes, :integer, default: 0
    field :is_draft, :boolean, default: true
    field :published_at, :utc_datetime

    many_to_many :tags, Tag,
      join_through: join_schema("posts_tags", {:post_id, :tag_id}),
      on_replace: :delete

    timestamps()
  end

  @spec changeset(t(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, fields())
    |> generate_body()
    |> generate_reading_time(attrs)
    |> validate_required([:title, :slug])
    |> preload_put_assoc(attrs, :tags, :tag_ids)
    |> unique_constraint(:slug)
  end

  # TODO: once this gets more complex, we'll split it into its own module
  defp generate_body(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:raw_body)
    |> Md.generate()
    |> append_space_between_alphanum_and_pattern([~r/<\/a>/, ~r/<\/code>/])
    |> then(&Ecto.Changeset.put_change(changeset, :body, &1))
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

  defp append_space_between_alphanum_and_pattern(html, regexes) when is_list(regexes) do
    Enum.reduce(regexes, html, &append_space_between_alphanum_and_pattern(&2, &1))
  end

  defp append_space_between_alphanum_and_pattern(html, %Regex{source: source}) do
    "(#{source})"
    |> List.wrap()
    |> Enum.concat(["(\\s*[a-zA-Z0-9])"])
    |> Enum.join("")
    |> Regex.compile!()
    |> then(&String.replace(html, &1, "\\1&nbsp;\\2"))
  end
end
