defmodule BlueJet.Repo.Migrations.CreateUnlockable do
  use Ecto.Migration

  def change do
    create table(:unlockables, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :avatar_id, references(:external_files, type: :binary_id, on_delete: :nilify_all)
      add :code, :string
      add :status, :string, null: false
      add :name, :string
      add :print_name, :string

      add :caption, :string
      add :description, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:unlockables, [:account_id, :code], where: "code IS NOT NULL")
    create unique_index(:unlockables, [:account_id, :print_name])
    create index(:unlockables, [:account_id, :name])
    create index(:unlockables, [:account_id, :status])
  end
end
