defmodule BlueJet.Repo.Migrations.CreateCustomer do
  use Ecto.Migration

  def change do
    create table(:customers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id)
      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :encrypted_password, :string
      add :display_name, :string

      timestamps()
    end

  end
end
