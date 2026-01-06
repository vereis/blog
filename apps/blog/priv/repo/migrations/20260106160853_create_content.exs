defmodule Blog.Repo.Migrations.CreateContent do
  use Ecto.Migration

  def change do
    create table(:content, primary_key: false) do
      add :slug, :string, primary_key: true
      add :type, :string, null: false
      add :title, :string, null: false
      add :source_path, :string, null: false
      add :raw_body, :text
      add :body, :text
      add :excerpt, :text
      add :description, :text
      add :external_url, :string
      add :is_draft, :boolean, default: false, null: false
      add :published_at, :utc_datetime
      add :reading_time_minutes, :integer
      add :headings, :text, null: false, default: "[]"
      add :permalinks, :text
      add :deleted_at, :utc_datetime

      timestamps()
    end

    create index(:content, [:type])
    create index(:content, [:is_draft])
    create index(:content, [:published_at])
    create index(:content, [:deleted_at])
  end
end
