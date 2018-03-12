defmodule BlueJet.Repo.Migrations.CreateOrderLineItem do
  use Ecto.Migration

  def change do
    create table(:order_line_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :parent_id, references(:order_line_items, type: :binary_id, on_delete: :delete_all)
      add :price_id, references(:prices, type: :binary_id, on_delete: :nilify_all)
      add :order_id, references(:orders, type: :binary_id, on_delete: :delete_all), null: false
      add :product_id, references(:products, type: :binary_id, on_delete: :nilify_all)

      add :target_id, :binary_id
      add :target_type, :string

      add :code, :string
      add :name, :string, null: false
      add :label, :string

      add :fulfillment_status, :string, null: false

      add :print_name, :string
      add :is_leaf, :boolean, null: false, default: true
      add :charge_quantity, :decimal, null: false
      add :order_quantity, :integer, null: false

      add :price_name, :string
      add :price_label, :string
      add :price_caption, :string
      add :price_order_unit, :string
      add :price_charge_unit, :string
      add :price_currency_code, :string
      add :price_charge_amount_cents, :integer
      add :price_estimate_average_percentage, :decimal
      add :price_estimate_maximum_percentage, :decimal
      add :price_tax_one_percentage, :decimal
      add :price_tax_two_percentage, :decimal
      add :price_tax_three_percentage, :decimal
      add :price_estimate_by_default, :boolean
      add :price_end_time, :utc_datetime

      add :sub_total_cents, :integer, null: false
      add :tax_one_cents, :integer, null: false
      add :tax_two_cents, :integer, null: false
      add :tax_three_cents, :integer, null: false
      add :grand_total_cents, :integer, null: false
      add :authorization_total_cents, :integer, null: false
      add :is_estimate, :boolean, null: false, default: false
      add :auto_fulfill, :boolean, null: false

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:order_line_items, [:account_id, :code], where: "code IS NOT NULL")
    create index(:order_line_items, [:account_id, :label], where: "label IS NOT NULL")
    create index(:order_line_items, [:account_id, :parent_id])
    create index(:order_line_items, [:account_id, :order_id])
    create index(:order_line_items, [:account_id, :price_id])
    create index(:order_line_items, [:account_id, :product_id])
    create index(:order_line_items, [:account_id, :target_id, :target_type], where: "target_id IS NOT NULL")
  end
end
