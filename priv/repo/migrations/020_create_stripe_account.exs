defmodule BlueJet.Repo.Migrations.CreateStripeAccount do
  use Ecto.Migration

  def change do
    create table(:stripe_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :stripe_user_id, :string
      add :stripe_livemode, :boolean
      add :stripe_access_token, :string
      add :stripe_refresh_token, :string
      add :stripe_publishable_key, :string
      add :stripe_scope, :string
      add :transaction_fee_percentage, :decimal, null: false

      timestamps()
    end

    create unique_index(:stripe_accounts, [:account_id])
  end
end