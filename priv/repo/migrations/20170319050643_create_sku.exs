defmodule BlueJet.Repo.Migrations.CreateSku do
  use Ecto.Migration

  def change do
    create table(:skus, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :avatar_id, references(:s3_files, type: :binary_id, on_delete: :nilify_all)
      add :code, :string
      add :status, :string, null: false
      add :name, :string, null: false
      add :print_name, :string, null: false
      add :unit_of_measure, :string, null: false
      add :variable_weight, :boolean, null: false, default: false

      add :storage_type, :string
      add :storage_size, :integer, null: false, default: 0
      add :stackable, :boolean, null: false, default: false

      add :caption, :string
      add :description, :text
      add :specification, :text
      add :storage_description, :text

      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:skus, :code)
    create unique_index(:skus, :print_name)
    create index(:skus, :name)
    create index(:skus, :status)
  end
end
