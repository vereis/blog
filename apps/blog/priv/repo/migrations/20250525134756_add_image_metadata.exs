defmodule Blog.Repo.Migrations.AddImageMetadata do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :path, :string, null: false
      add :width, :integer, null: false
      add :height, :integer, null: false
    end
  end
end
