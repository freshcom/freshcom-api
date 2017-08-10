defmodule BlueJet.Repo.Migrations.CreateOrderCharge do
  use Ecto.Migration

  def change do
    create table(:order_charges, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :stripe_charge_id, :string

      add :status, :string
      add :authorized_amount_cents, :integer
      add :captured_amount_cents, :integer
      add :refunded_amount_cents, :integer

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :order_id, references(:orders, type: :binary_id, on_delete: :delete_all), null: false

      add :authorized_at, :utc_datetime
      add :captured_at, :utc_datetime
      add :refunded_at, :utc_datetime

      timestamps()
    end

    create index(:order_charges, [:account_id])
    create index(:order_charges, [:order_id])
  end
end
