defmodule BlueJet.Repo.Migrations.CreatePointAccount do
  use Ecto.Migration

  def change do
    create table(:point_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string
      add :balance, :integer

      add :customer_id, references(:customers, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:point_accounts, [:customer_id])
    create index(:point_accounts, [:account_id])
  end
end