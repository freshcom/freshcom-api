defmodule BlueJet.Repo.Migrations.CreateExternalFile do
  use Ecto.Migration

  def change do
    create table(:external_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :content_type, :string
      add :size_bytes, :integer
      add :public_readable, :boolean, default: true, null: false
      add :version_name, :string
      add :version_label, :string
      add :system_tag, :string
      add :original_id, references(:external_files, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create index(:external_files, :status)
    create index(:external_files, :system_tag)
    create index(:external_files, :version_label)
  end
end
