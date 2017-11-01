defmodule BlueJet.Repo.Migrations.CreatePayment do
  use Ecto.Migration

  def change do
    create table(:payments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, default: "pending"

      add :gateway, :string
      add :processor, :string
      add :method, :string

      add :pending_amount_cents, :integer
      add :authorized_amount_cents, :integer
      add :paid_amount_cents, :integer
      add :refunded_amount_cents, :integer, null: false, default: 0
      add :transaction_fee_cents, :integer

      add :billing_address_line_one, :string
      add :billing_address_line_two, :string
      add :billing_address_province, :string
      add :billing_address_city, :string
      add :billing_address_country_code, :string
      add :billing_address_postal_code, :string

      add :stripe_charge_id, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :order_id, references(:orders, type: :binary_id, on_delete: :delete_all), null: false
      add :customer_id, references(:customers, type: :binary_id, on_delete: :delete_all)

      add :authorized_at, :utc_datetime
      add :captured_at, :utc_datetime
      add :refunded_at, :utc_datetime

      timestamps()
    end

    create index(:payments, [:account_id])
    create index(:payments, [:order_id])
  end
end
