defmodule BlueJet.Repo.Migrations.CreateUnlockable do
  use Ecto.Migration

  def change do
    create table(:unlockables, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :code, :string
      add :name, :string, null: false
      add :label, :string

      add :print_name, :string

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :avatar_id, references(:external_files, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:unlockables, [:account_id, :code], where: "code IS NOT NULL")
    create index(:unlockables, [:account_id, :status])
    create index(:unlockables, [:account_id, :name])
    create index(:unlockables, [:account_id, :label], where: "label IS NOT NULL")
  end
end
