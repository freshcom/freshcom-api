defmodule BlueJet.Repo.Migrations.CreateExternalFileCollection do
  use Ecto.Migration

  def change do
    create table(:external_file_collections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all)
      add :status, :string, null: false
      add :code, :string
      add :name, :string, null: false
      add :label, :string

      add :content_type, :string

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :owner_id, :binary_id
      add :owner_type, :string

      timestamps()
    end

    create unique_index(:external_file_collections, [:account_id, :code], where: "code IS NOT NULL")
    create index(:external_file_collections, :account_id)
    create index(:external_file_collections, [:account_id, :status])
    create index(:external_file_collections, [:account_id, :name])
    create index(:external_file_collections, [:account_id, :label])
    create index(:external_file_collections, [:owner_type, :owner_id])
  end
end
