defmodule BlueJet.Repo.Migrations.CreateExternalFileCollectionMembership do
  use Ecto.Migration

  def change do
    create table(:external_file_collection_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :collection_id, references(:external_file_collections, on_delete: :delete_all, type: :binary_id)
      add :file_id, references(:external_files, on_delete: :delete_all, type: :binary_id)

      add :sort_index, :integer, null: false, default: 100

      timestamps()
    end
    create index(:external_file_collection_memberships, [:account_id, :collection_id])
    create index(:external_file_collection_memberships, [:account_id, :file_id])
    create index(:external_file_collection_memberships, [:account_id, :sort_index])
  end
end
