defmodule Blog.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :label, :string, null: false

      timestamps()
    end

    create unique_index(:tags, [:label])
  end
end
