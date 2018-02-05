defmodule BlueJet.Repo.Migrations.CreateFileCollection do
  use Ecto.Migration

  def change do
    create table(:file_collections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all)
      add :owner_id, :binary_id
      add :owner_type, :string

      add :status, :string, null: false
      add :code, :string
      add :name, :string, null: false
      add :label, :string

      add :content_type, :string

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:file_collections, [:account_id, :code], where: "code IS NOT NULL")
    create index(:file_collections, [:account_id, :status])
    create index(:file_collections, [:account_id, :name])
    create index(:file_collections, [:account_id, :label], where: "label IS NOT NULL")
    create index(:file_collections, [:account_id, :owner_id, :owner_type], where: "owner_id IS NOT NULL")
  end
end
