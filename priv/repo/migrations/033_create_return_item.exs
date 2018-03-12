defmodule BlueJet.Repo.Migrations.CreateReturnItem do
  use Ecto.Migration

  def change do
    create table(:return_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :package_id, references(:return_packages, type: :binary_id, on_delete: :delete_all), null: false
      add :fulfillment_item_id, references(:fulfillment_items, type: :binary_id, on_delete: :delete_all), null: false
      add :order_id, references(:orders, type: :binary_id, on_delete: :nilify_all)
      add :order_line_item_id, references(:order_line_items, type: :binary_id, on_delete: :nilify_all)

      add :target_id, :binary_id
      add :target_type, :string

      add :source_id, :binary_id
      add :source_type, :string

      add :status, :string, null: false
      add :code, :string
      add :name, :string
      add :label, :string

      add :quantity, :integer, null: false
      add :print_name, :string

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:return_items, [:account_id, :code], where: "code IS NOT NULL")
    create index(:return_items, :account_id)
    create index(:return_items, [:account_id, :status])
    create index(:return_items, [:account_id, :label], where: "label IS NOT NULL")
    create index(:return_items, [:account_id, :package_id])
    create index(:return_items, [:account_id, :fulfillment_item_id])
    create index(:return_items, [:account_id, :source_id, :source_type], where: "source_id IS NOT NULL")
    create index(:return_items, [:account_id, :target_id, :target_type], where: "target_id IS NOT NULL")
  end
end
