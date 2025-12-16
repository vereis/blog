defmodule Blog.Repo.Migrations.AddDescriptionToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :description, :text
    end
  end
end
