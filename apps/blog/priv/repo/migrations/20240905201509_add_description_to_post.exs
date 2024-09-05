defmodule Blog.Repo.Migrations.AddDescriptionToPost do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :description, :string
    end
  end
end
