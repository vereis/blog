defmodule Blog.Repo.SQLite.Migrations.AddImagesTable do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :name, :string, null: false
      add :content_type, :string, null: false
      add :data, :blob, null: false
      add :path, :string, null: false
      add :width, :integer, null: false
      add :height, :integer, null: false

      timestamps()
    end

    create unique_index(:images, [:name])
    create unique_index(:images, [:path])
  end
end
