defmodule Blog.Repo.SQLite.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :url, :string, null: false
      add :description, :text

      timestamps()
    end

    create index(:projects, [:name])
  end
end
