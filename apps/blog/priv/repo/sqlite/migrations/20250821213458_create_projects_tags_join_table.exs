defmodule Blog.Repo.SQLite.Migrations.CreateProjectsTagsJoinTable do
  use Ecto.Migration

  def change do
    create table(:projects_tags, primary_key: false) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:projects_tags, [:project_id, :tag_id])
    create index(:projects_tags, [:tag_id])
  end
end