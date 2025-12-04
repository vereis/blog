defmodule Blog.Repo.Migrations.CreateProjectsTags do
  # excellent_migrations:safety-assured-for-this-file column_reference_added

  use Ecto.Migration

  def change do
    create table(:projects_tags, primary_key: false) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
    end

    create index(:projects_tags, [:project_id])
    create index(:projects_tags, [:tag_id])
    create unique_index(:projects_tags, [:project_id, :tag_id])
  end
end
