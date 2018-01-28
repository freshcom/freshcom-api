defmodule BlueJet.Repo.Migrations.CreateProductCollection do
  use Ecto.Migration

  def change do
    create table(:product_collections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :avatar_id, references(:external_files, type: :binary_id, on_delete: :nilify_all)

      add :status, :string, null: false
      add :code, :string
      add :name, :string, null: false
      add :label, :string

      add :sort_index, :integer, null: false

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:product_collections, [:account_id, :code], where: "code IS NOT NULL")
    create index(:product_collections, [:account_id, :status])
    create index(:product_collections, [:account_id, :name])
    create index(:product_collections, [:account_id, :label], where: "label IS NOT NULL")
  end
end
