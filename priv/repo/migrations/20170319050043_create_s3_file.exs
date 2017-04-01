defmodule BlueJet.Repo.Migrations.CreateS3File do
  use Ecto.Migration

  def change do
    create table(:s3_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :content_type, :string
      add :size_bytes, :integer
      add :public_readable, :boolean, default: true, null: false
      add :version_name, :string
      add :version_label, :string
      add :system_tag, :string
      add :original_id, references(:s3_files, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create index(:s3_files, :status)
    create index(:s3_files, :system_tag)
    create index(:s3_files, :version_label)
  end
end
