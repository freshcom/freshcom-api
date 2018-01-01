defmodule BlueJet.Repo.Migrations.CreateExternalFile do
  use Ecto.Migration

  def change do
    create table(:external_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all)
      add :status, :string, null: false, default: "pending"
      add :code, :string
      add :name, :string, null: false
      add :label, :string

      add :content_type, :string
      add :size_bytes, :integer
      add :public_readable, :boolean, default: true, null: false

      add :version_name, :string
      add :version_label, :string
      add :system_tag, :string
      add :original_id, references(:external_files, type: :binary_id, on_delete: :delete_all)

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :user_id, references(:users, type: :binary_id)

      timestamps()
    end

    create unique_index(:external_files, [:account_id, :code], where: "code IS NOT NULL")
    create index(:external_files, [:account_id, :name])
    create index(:external_files, [:account_id, :label], where: "label IS NOT NULL")
    create index(:external_files, [:account_id, :content_type])
    create index(:external_files, [:account_id, :status])
    create index(:external_files, [:account_id, :system_tag])
    create index(:external_files, [:account_id, :version_label])
    create index(:external_files, [:account_id, :user_id])
    create index(:external_files, [:account_id, :original_id])
  end
end
