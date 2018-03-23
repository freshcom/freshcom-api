defmodule BlueJet.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all)
      add :default_account_id, references(:accounts, type: :binary_id), null: false
      add :status, :string

      add :username, :string, null: false
      add :email, :string
      add :phone_number, :string
      add :encrypted_password, :string
      add :name, :string
      add :first_name, :string
      add :last_name, :string

      add :auth_method, :string, null: false
      add :tfa_code, :string
      add :tfa_code_expires_at, :utc_datetime

      add :email_verification_token, :string
      add :email_verification_token_expires_at, :utc_datetime
      add :email_verified, :boolean, null: false
      add :email_verified_at, :utc_datetime

      add :password_reset_token, :string
      add :password_reset_token_expires_at, :utc_datetime
      add :password_updated_at, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:email], where: "account_id IS NULL")
    create unique_index(:users, [:username], where: "account_id IS NULL")
    create unique_index(:users, [:password_reset_token])
    create unique_index(:users, [:email_verification_token])
    create unique_index(:users, [:account_id, :username])

    create index(:users, [:account_id, :status])
  end
end
