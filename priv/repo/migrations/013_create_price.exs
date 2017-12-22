defmodule BlueJet.Repo.Migrations.CreatePrice do
  use Ecto.Migration

  def change do
    create table(:prices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :code, :string
      add :name, :string, null: false
      add :label, :string

      add :currency_code, :string, null: false, default: "CAD"
      add :charge_amount_cents, :integer, null: false
      add :charge_unit, :string, null: false
      add :order_unit, :string, null: false

      add :estimate_average_percentage, :decimal
      add :estimate_maximum_percentage, :decimal
      add :minimum_order_quantity, :integer, null: false, default: 1
      add :estimate_by_default, :boolean, null: false, default: false

      add :tax_one_percentage, :decimal, null: false, default: 0
      add :tax_two_percentage, :decimal, null: false, default: 0
      add :tax_three_percentage, :decimal, null: false, default: 0

      add :start_time, :utc_datetime
      add :end_time, :utc_datetime

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :product_id, references(:products, type: :binary_id, on_delete: :delete_all), null: false
      add :parent_id, references(:prices, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:prices, [:account_id, :code], where: "code IS NOT NULL")
    create index(:prices, :account_id)
    create index(:prices, :product_id)
    create index(:prices, :minimum_order_quantity)
    create index(:prices, [:product_id, :status])
  end
end
