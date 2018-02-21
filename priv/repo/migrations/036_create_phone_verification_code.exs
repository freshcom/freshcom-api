defmodule BlueJet.Repo.Migrations.CreatePhoneVerificationCode do
  use Ecto.Migration

  def change do
    create table(:phone_verification_codes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :phone_number, :string, null: false
      add :value, :string, null: false
      add :expires_at, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:phone_verification_codes, [:account_id, :value, :expires_at])
    create index(:phone_verification_codes, [:account_id, :phone_number])
  end
end
