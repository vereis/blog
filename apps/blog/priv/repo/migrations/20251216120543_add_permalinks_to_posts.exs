defmodule Blog.Repo.Migrations.AddPermalinksToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :permalinks, :text, default: "[]"
    end
  end
end
