defmodule BlueJet.Repo.Migrations.CreateCustomer do
  use Ecto.Migration

  def change do
    create table(:customers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id)
      add :status, :string
      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :encrypted_password, :string
      add :display_name, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:customers, [:email, :account_id])
  end
end
