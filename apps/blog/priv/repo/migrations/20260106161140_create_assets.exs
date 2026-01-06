defmodule Blog.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets, primary_key: false) do
      add :slug, :string, primary_key: true
      add :content_slug, :string
      add :source_path, :string, null: false
      add :name, :string, null: false
      add :data, :binary, null: false
      add :data_hash, :string, null: false
      add :content_type, :string, null: false
      add :metadata, :text, null: false
      add :deleted_at, :utc_datetime

      timestamps()
    end

    create index(:assets, [:content_slug])
    create index(:assets, [:deleted_at])
  end
end
