defmodule BlueJet.Repo.Migrations.CreateSMSTemplate do
  use Ecto.Migration

  def change do
    create table(:sms_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :system_label, :string
      add :name, :string, null: false

      add :to, :string
      add :body, :text
      add :description, :text

      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create index(:sms_templates, [:account_id, :name])
  end
end
