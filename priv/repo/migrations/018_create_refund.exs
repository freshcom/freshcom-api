defmodule BlueJet.Repo.Migrations.CreateRefund do
  use Ecto.Migration

  def change do
    create table(:refunds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string
      add :gateway, :string
      add :processor, :string
      add :method, :string

      add :amount_cents, :integer
      add :processor_fee_cents, :integer
      add :freshcom_fee_cents, :integer

      add :notes, :text

      add :payment_id, references(:payments, type: :binary_id, on_delete: :delete_all), null: false
      add :stripe_refund_id, :string
      add :stripe_transfer_reversal_id, :string

      add :owner_id, :binary_id
      add :owner_type, :string

      add :target_id, :binary_id
      add :target_type, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"


      timestamps()
    end

    create index(:refunds, [:account_id])
    create index(:refunds, [:payment_id])
  end
end