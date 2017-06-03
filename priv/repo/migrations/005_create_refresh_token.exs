defmodule BlueJet.Repo.Migrations.CreateRefreshToken do
  use Ecto.Migration

  def change do
    create table(:refresh_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :customer_id, references(:customers, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
  end
end
