defmodule BlueJet.Repo.Migrations.CreateRoleInstance do
  use Ecto.Migration

  def change do
    create table(:role_instances, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :account_membership_id, references(:account_memberships, type: :binary_id, on_delete: :delete_all), null: false
      add :role_id, references(:roles, type: :binary_id, on_delete: :delete_all), null: false

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:role_instances, [:account_membership_id, :role_id])
  end
end
