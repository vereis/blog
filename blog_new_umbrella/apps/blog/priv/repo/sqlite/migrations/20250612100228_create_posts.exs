defmodule Blog.Repo.SQLite.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :body, :text, default: ""
      add :raw_body, :text, default: ""
      add :slug, :string, null: false
      add :reading_time_minutes, :integer, default: 0
      add :is_draft, :boolean, default: true
      add :is_redacted, :boolean, default: false
      add :published_at, :utc_datetime
      add :description, :text
      add :headings, :text

      timestamps()
    end

    create unique_index(:posts, [:slug])
  end
end
