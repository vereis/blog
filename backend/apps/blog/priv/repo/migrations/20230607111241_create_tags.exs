defmodule Blog.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :label, :string, null: false
      timestamps()
    end

    create table(:posts_tags) do
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:tags, [:label])
    create unique_index(:posts_tags, [:post_id, :tag_id])
  end
end
