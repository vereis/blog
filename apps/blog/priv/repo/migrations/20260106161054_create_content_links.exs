defmodule Blog.Repo.Migrations.CreateContentLinks do
  use Ecto.Migration

  def change do
    create table(:content_links, primary_key: false) do
      add :source_slug, :string, null: false, primary_key: true
      add :target_slug, :string, null: false, primary_key: true
      add :context, :string, null: false, primary_key: true

      timestamps()
    end

    create index(:content_links, [:target_slug])
  end
end
