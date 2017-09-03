defmodule BlueJet.Repo.Migrations.CreatePrice do
  use Ecto.Migration

  def change do
    create table(:prices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :name, :string
      add :label, :string, null: false
      add :caption, :string
      add :currency_code, :string, null: false, default: "CAD"
      add :charge_cents, :integer, null: false
      add :estimate_average_percentage, :decimal
      add :estimate_maximum_percentage, :decimal
      add :minimum_order_quantity, :integer, null: false, default: 1
      add :order_unit, :string, null: false
      add :charge_unit, :string, null: false
      add :public_orderable, :boolean, null: false, default: true
      add :estimate_by_default, :boolean, null: false, default: false
      add :tax_one_rate, :integer, null: false, default: 0
      add :tax_two_rate, :integer, null: false, default: 0
      add :tax_three_rate, :integer, null: false, default: 0
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :product_item_id, references(:product_items, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:prices, [:account_id])
    create index(:prices, [:product_item_id])
  end
end
