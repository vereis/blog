defmodule Blog.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :body, :text, null: false
      add :raw_body, :text, null: false
      add :slug, :string, null: false
      add :reading_time_minutes, :integer, null: false
      add :is_draft, :boolean, default: false, null: false
      add :published_at, :utc_datetime
      add :hash, :string
      add :headings, :text, null: false

      timestamps()
    end

    create unique_index(:posts, [:slug])
    create index(:posts, [:is_draft])
    create index(:posts, [:published_at])
  end
end
