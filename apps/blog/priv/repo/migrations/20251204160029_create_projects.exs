defmodule Blog.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :url, :string, null: false
      add :description, :text, null: false
      add :hash, :string

      timestamps()
    end

    create unique_index(:projects, [:name])
  end
end
