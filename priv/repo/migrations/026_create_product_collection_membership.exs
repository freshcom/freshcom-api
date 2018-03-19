defmodule BlueJet.Repo.Migrations.CreateProductCollectionMembership do
  use Ecto.Migration

  def change do
    create table(:product_collection_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :collection_id, references(:product_collections, on_delete: :delete_all, type: :binary_id)
      add :product_id, references(:products, on_delete: :delete_all, type: :binary_id)

      add :sort_index, :integer, null: false

      timestamps()
    end

    create unique_index(:product_collection_memberships, [:product_id, :collection_id])
    create index(:product_collection_memberships, [:account_id, :collection_id])
    create index(:product_collection_memberships, [:account_id, :product_id])
    create index(:product_collection_memberships, [:account_id, :sort_index])
  end
end
