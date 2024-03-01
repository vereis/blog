defmodule Blog.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      # Core content
      add(:title, :string, null: false)
      add(:body, :text, default: "")
      add(:raw_body, :text, default: "")

      # Metadata
      add(:slug, :string, null: false)
      add(:reading_time_minutes, :integer, default: 0)
      add(:is_draft, :boolean, default: true)
      add(:published_at, :utc_datetime)

      timestamps()
    end

    create(unique_index(:posts, [:slug]))
  end
end
