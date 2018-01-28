defmodule BlueJet.Repo.Migrations.CreateBalanceSettings do
  use Ecto.Migration

  def change do
    create table(:balance_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :stripe_user_id, :string
      add :stripe_livemode, :boolean
      add :stripe_access_token, :string
      add :stripe_refresh_token, :string
      add :stripe_publishable_key, :string
      add :stripe_scope, :string
      add :stripe_variable_fee_percentage, :decimal, null: false
      add :stripe_fixed_fee_cents, :integer, null: false

      add :freshcom_transaction_fee_percentage, :decimal, null: false

      add :country, :string
      add :default_currency, :string

      timestamps()
    end

    create unique_index(:balance_settings, :account_id)
  end
end