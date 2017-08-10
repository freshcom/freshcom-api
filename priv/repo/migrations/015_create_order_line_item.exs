defmodule BlueJet.Repo.Migrations.CreateOrderLineItem do
  use Ecto.Migration

  def change do
    create table(:order_line_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :name, :string
      add :print_name, :string
      add :description, :text

      add :is_leaf, :boolean, null: false, default: true

      add :price_name, :string
      add :price_label, :string
      add :price_caption, :string
      add :price_order_unit, :string
      add :price_charge_unit, :string
      add :price_currency_code, :string
      add :price_charge_cents, :integer
      add :price_estimate_cents, :integer
      add :price_tax_one_rate, :integer
      add :price_tax_two_rate, :integer
      add :price_tax_three_rate, :integer

      add :charge_quantity, :decimal
      add :order_quantity, :integer, null: false, default: 1

      add :sub_total_cents, :integer, null: false
      add :tax_one_cents, :integer, null: false
      add :tax_two_cents, :integer, null: false
      add :tax_three_cents, :integer, null: false
      add :grand_total_cents, :integer, null: false

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :price_id, references(:prices, type: :binary_id)
      add :order_id, references(:orders, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:order_line_items, [:account_id])
    create index(:order_line_items, [:order_id])
    create index(:order_line_items, [:price_id])
  end
end
