defmodule BlueJet.Repo.Migrations.CreateRefreshToken do
  use Ecto.Migration

  def change do
    create table(:refresh_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :scope, :text

      timestamps()
    end

    create index(:refresh_tokens, [:account_id, :user_id])
    create index(:refresh_tokens, :user_id)
  end
end
