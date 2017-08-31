defmodule BlueJet.Repo.Migrations.CreateProductItem do
  use Ecto.Migration

  def change do
    create table(:product_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :code, :string
      add :status, :string, null: false
      add :name_sync, :string, null: false, default: "disabled"
      add :name, :string, null: false
      add :short_name, :string
      add :sort_index, :integer, null: false, default: 9999
      add :source_quantity, :integer, null: false, default: 1
      add :primary, :boolean, null: false, default: false
      add :maximum_public_order_quantity, :integer, null: false, default: 9999

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :product_id, references(:products, type: :binary_id, on_delete: :delete_all), null: false
      add :sku_id, references(:skus, type: :binary_id, on_delete: :nilify_all)
      add :unlockable_id, references(:unlockables, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:product_items, [:account_id, :code], where: "code IS NOT NULL")
    create index(:product_items, [:account_id, :sort_index])
    create index(:product_items, [:account_id, :product_id])
  end
end
