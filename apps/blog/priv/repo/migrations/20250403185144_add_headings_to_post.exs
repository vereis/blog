defmodule Blog.Repo.Migrations.AddHeadingsToPost do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :headings, {:array, :map}, default: []
    end
  end
end
