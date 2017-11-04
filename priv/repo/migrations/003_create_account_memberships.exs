defmodule BlueJet.Repo.Migrations.CreateAccountMemberships do
  use Ecto.Migration

  def change do
    create table(:account_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

  end
end
