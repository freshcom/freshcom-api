defmodule BlueJet.Repo.Migrations.CreateRole do
  use Ecto.Migration

  def change do
    create table(:roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "active"
      add :name, :string
      add :system_label, :string
      add :permissions, :map, null: false, default: "{}"

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end
  end
end
