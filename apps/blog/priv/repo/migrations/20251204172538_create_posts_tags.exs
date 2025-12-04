defmodule Blog.Repo.Migrations.CreatePostsTags do
  # excellent_migrations:safety-assured-for-this-file column_reference_added

  use Ecto.Migration

  def change do
    create table(:posts_tags, primary_key: false) do
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
    end

    create index(:posts_tags, [:post_id])
    create index(:posts_tags, [:tag_id])
    create unique_index(:posts_tags, [:post_id, :tag_id])
  end
end
