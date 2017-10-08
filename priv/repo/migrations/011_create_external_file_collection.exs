defmodule BlueJet.Repo.Migrations.CreateExternalFileCollection do
  use Ecto.Migration

  def change do
    create table(:external_file_collections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all)
      add :name, :string
      add :label, :string, null: false
      add :content_type, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :sku_id, references(:skus, type: :binary_id, on_delete: :delete_all)
      add :customer_id, references(:customers, type: :binary_id, on_delete: :delete_all)
      add :unlockable_id, references(:unlockables, type: :binary_id, on_delete: :delete_all)
      add :product_id, references(:products, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:external_file_collections, [:account_id, :sku_id, :label], where: "sku_id IS NOT NULL")
  end
end
