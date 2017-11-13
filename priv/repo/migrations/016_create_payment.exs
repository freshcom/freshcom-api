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

      add :amount_cents, :integer, null: false
      add :refunded_amount_cents, :integer, null: false, default: 0
      add :gross_amount_cents, :integer, null: false
      add :transaction_fee_cents, :integer, null: false, default: 0
      add :refunded_transaction_fee_cents, :integer, null: false, default: 0
      add :net_amount_cents, :integer, null: false

      add :billing_address_line_one, :string
      add :billing_address_line_two, :string
      add :billing_address_province, :string
      add :billing_address_city, :string
      add :billing_address_country_code, :string
      add :billing_address_postal_code, :string

      add :stripe_charge_id, :string
      add :stripe_customer_id, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :owner_id, :binary_id
      add :owner_type, :string

      add :target_id, :binary_id
      add :target_type, :string

      add :authorized_at, :utc_datetime
      add :captured_at, :utc_datetime
      add :refunded_at, :utc_datetime

      timestamps()
    end

    create index(:payments, [:account_id])
  end
end
