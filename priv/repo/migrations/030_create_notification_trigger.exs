defmodule BlueJet.Repo.Migrations.CreateNotificationTrigger do
  use Ecto.Migration

  def change do
    create table(:notification_triggers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :name, :string
      add :system_label, :string

      add :event, :string, null: false
      add :description, :text

      add :action_target, :string, null: false
      add :action_type, :string, null: false

      timestamps()
    end

    create index(:notification_triggers, [:account_id, :name])
    create index(:notification_triggers, [:account_id, :status])
    create index(:notification_triggers, [:account_id, :event])
    create index(:notification_triggers, [:account_id, :action_type, :action_target], where: "action_type IS NOT NULL")
  end
end
