# excellent_migrations:safety-assured-for-this-file column_removed
defmodule Blog.Repo.Migrations.RemoveHashFields do
  use Ecto.Migration

  def up do
    alter table(:posts) do
      remove :hash
    end

    drop index(:assets, [:hash])

    alter table(:assets) do
      remove :hash
    end

    alter table(:projects) do
      remove :hash
    end
  end

  def down do
    alter table(:posts) do
      add :hash, :string
    end

    alter table(:assets) do
      add :hash, :string
    end

    create index(:assets, [:hash])

    alter table(:projects) do
      add :hash, :string
    end
  end
end
