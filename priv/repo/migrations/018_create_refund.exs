defmodule BlueJet.Repo.Migrations.CreateRefund do
  use Ecto.Migration

  def change do
    create table(:refunds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :amount_cents, :integer

      add :payment_id, references(:payments, type: :binary_id, on_delete: :delete_all), null: false

      add :stripe_refund_id, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"


      timestamps()
    end

    create index(:refunds, [:account_id])
    create index(:refunds, [:payment_id])
  end
end