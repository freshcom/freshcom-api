defmodule BlueJet.Repo.Migrations.CreateNotificationTrigger do
  use Ecto.Migration

  def change do
    create table(:notification_triggers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string
      add :system_label, :string

      add :endpoint, :string
      add :description, :text

      add :target_id, :binary_id
      add :target_type, :string

      timestamps()
    end

    create index(:notification_triggers, [:account_id, :name])
    create index(:notification_triggers, [:account_id, :endpoint], where: "endpoint IS NOT NULL")
    create index(:notification_triggers, [:account_id, :target_id, :target_type], where: "target_id IS NOT NULL")
  end
end
