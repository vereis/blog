defmodule Blog.Repo.Migrations.AddPermalinksToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      # excellent_migrations:safety-assured-for-next-line column_added_with_default
      add :permalinks, :text, default: "[]"
    end
  end
end
