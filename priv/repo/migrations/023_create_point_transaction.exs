defmodule BlueJet.Repo.Migrations.CreatePointTransaction do
  use Ecto.Migration

  def change do
    create table(:point_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :point_account_id, references(:point_accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :amount, :integer

      add :source_id, :binary_id
      add :source_type, :string

      timestamps()
    end

    create index(:point_transactions, [:account_id])
    create index(:point_transactions, [:point_account_id])
  end
end