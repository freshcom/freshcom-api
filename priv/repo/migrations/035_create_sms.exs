defmodule BlueJet.Repo.Migrations.CreateSMS do
  use Ecto.Migration

  def change do
    create table(:sms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :recipient_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :trigger_id, references(:notification_triggers, type: :binary_id, on_delete: :nilify_all)
      add :template_id, references(:sms_templates, type: :binary_id, on_delete: :nilify_all)

      add :status, :string, null: false

      add :to, :string
      add :body, :text
      add :locale, :string

      timestamps()
    end

    create index(:sms, [:account_id, :status])
    create index(:sms, [:account_id, :to])
    create index(:sms, [:account_id, :trigger_id])
    create index(:sms, [:account_id, :template_id])
  end
end
