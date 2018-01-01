defmodule BlueJet.Repo.Migrations.CreateRefund do
  use Ecto.Migration

  def change do
    create table(:refunds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string
      add :code, :string
      add :label, :string

      add :gateway, :string, null: false
      add :processor, :string
      add :method, :string

      add :amount_cents, :integer
      add :processor_fee_cents, :integer, null: false, default: 0
      add :freshcom_fee_cents, :integer, null: false, default: 0

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :payment_id, references(:payments, type: :binary_id, on_delete: :delete_all), null: false
      add :stripe_refund_id, :string
      add :stripe_transfer_reversal_id, :string

      add :owner_id, :binary_id
      add :owner_type, :string

      add :target_id, :binary_id
      add :target_type, :string

      timestamps()
    end

    create unique_index(:refunds, [:account_id, :code], where: "code IS NOT NULL")
    create index(:refunds, [:account_id, :label], where: "label IS NOT NULL")
    create index(:refunds, [:account_id, :payment_id])
  end
end