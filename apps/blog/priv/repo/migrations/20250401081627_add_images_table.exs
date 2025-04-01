defmodule Blog.Repo.Migrations.AddImagesTable do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :name, :string, null: false
      add :content_type, :string, null: false
      add :data, :blob, null: false

      timestamps()
    end

    create unique_index(:images, [:name])
  end
end
