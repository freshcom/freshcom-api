defmodule BlueJet.Repo.Migrations.CreateS3FileSet do
  use Ecto.Migration

  def change do
    create table(:s3_file_sets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :label, :string, null: false
      add :content_type, :string
      add :s3_file_ids, {:array, :binary_id}, null: false, default: []
      add :sku_id, references(:skus, type: :binary_id, on_delete: :delete_all)

      add :translations, :map

      timestamps()
    end

    create index(:s3_file_sets, [:sku_id, :label])
  end
end
