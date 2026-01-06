defmodule Blog.Repo.Migrations.CreatePermalinks do
  use Ecto.Migration

  def change do
    create table(:permalinks, primary_key: false) do
      add :path, :string, primary_key: true
      add :content_slug, :string, null: false

      timestamps(updated_at: false)
    end

    create index(:permalinks, [:content_slug])
  end
end
