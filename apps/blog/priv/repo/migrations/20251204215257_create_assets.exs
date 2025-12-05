defmodule Blog.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets) do
      add :name, :string, null: false
      add :path, :string, null: false
      add :data, :binary, null: false
      add :width, :integer, null: false
      add :height, :integer, null: false
      add :content_type, :string, null: false
      add :type, :string, null: false
      add :hash, :string

      timestamps()
    end

    create unique_index(:assets, [:name])
    create unique_index(:assets, [:path])
    create index(:assets, [:hash])
    create index(:assets, [:type])
  end
end
