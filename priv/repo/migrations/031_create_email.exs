defmodule BlueJet.Repo.Migrations.CreateEmail do
  use Ecto.Migration

  def change do
    create table(:emails, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false

      add :recipient_email, :string
      add :sender_email, :string

      add :content, :text

      add :recipient_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false
      add :trigger_id, references(:notification_triggers, type: :binary_id, on_delete: :nilify_all), null: false
      add :template_id, references(:email_templates, type: :binary_id, on_delete: :nilify_all), null: false

      timestamps()
    end

    create index(:emails, [:account_id, :status])
    create index(:emails, [:account_id, :recipient_email])
    create index(:emails, [:account_id, :recipient_id])
    create index(:emails, [:account_id, :trigger_id])
    create index(:emails, [:account_id, :template_id])
  end
end
