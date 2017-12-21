defmodule BlueJet.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string
      add :username, :string
      add :email, :string, null: false
      add :encrypted_password, :string
      add :first_name, :string
      add :last_name, :string
      add :account_id, references(:accounts, type: :binary_id)
      add :default_account_id, references(:accounts, type: :binary_id)

      timestamps()
    end

    create unique_index(:users, [:account_id, :email])
    create unique_index(:users, [:account_id, :username])
    create index(:users, :account_id)
  end
end
