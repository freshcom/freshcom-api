defmodule BlueJet.Repo.Migrations.CreatePayment do
  use Ecto.Migration

  def change do
    create table(:payments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, default: "pending"
      add :code, :string
      add :label, :string

      add :gateway, :string, null: false
      add :processor, :string
      add :method, :string

      add :amount_cents, :integer, null: false
      add :refunded_amount_cents, :integer, null: false, default: 0
      add :gross_amount_cents, :integer, null: false, default: 0

      add :processor_fee_cents, :integer, null: false, default: 0
      add :refunded_processor_fee_cents, :integer, null: false, default: 0

      add :freshcom_fee_cents, :integer, null: false, default: 0
      add :refunded_freshcom_fee_cents, :integer, null: false, default: 0

      add :net_amount_cents, :integer, null: false, default: 0

      add :billing_address_line_one, :string
      add :billing_address_line_two, :string
      add :billing_address_province, :string
      add :billing_address_city, :string
      add :billing_address_country_code, :string
      add :billing_address_postal_code, :string

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :authorized_at, :utc_datetime
      add :captured_at, :utc_datetime
      add :refunded_at, :utc_datetime

      add :stripe_charge_id, :string
      add :stripe_transfer_id, :string
      add :stripe_customer_id, :string

      add :owner_id, :binary_id
      add :owner_type, :string

      add :target_id, :binary_id
      add :target_type, :string

      timestamps()
    end

    create unique_index(:payments, [:account_id, :code], where: "code IS NOT NULL")
    create index(:payments, [:account_id, :status])
    create index(:payments, [:account_id, :label], where: "label IS NOT NULL")
    create index(:payments, [:account_id, :owner_id, :owner_type], where: "owner_id IS NOT NULL")
    create index(:payments, [:account_id, :target_id, :target_type], where: "target_id IS NOT NULL")
  end
end
