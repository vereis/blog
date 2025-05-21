defmodule Blog.Repo.Migrations.AddRedactedPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :is_redacted, :boolean, default: false, null: false
    end

    create index(:posts, [:is_redacted])
  end
end
