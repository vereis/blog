defmodule Blog.Repo.Migrations.AddExcerptToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :excerpt, :text
    end
  end
end
