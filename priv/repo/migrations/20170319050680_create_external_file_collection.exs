defmodule BlueJet.Repo.Migrations.CreateExternalFileCollection do
  use Ecto.Migration

  def change do
    create table(:external_file_collections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all)
      add :name, :string
      add :label, :string, null: false
      add :content_type, :string
      add :file_ids, {:array, :binary_id}, null: false, default: []
      add :sku_id, references(:skus, type: :binary_id, on_delete: :delete_all)

      add :translations, :map

      timestamps()
    end

    create index(:external_file_collections, [:sku_id, :label])
  end
end
