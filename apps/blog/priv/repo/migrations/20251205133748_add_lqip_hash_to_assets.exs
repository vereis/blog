defmodule Blog.Repo.Migrations.AddLqipHashToAssets do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      add :lqip_hash, :integer
    end

    create index(:assets, [:lqip_hash])
  end
end
