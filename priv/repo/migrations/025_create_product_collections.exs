defmodule BlueJet.Repo.Migrations.CreateProductCollection do
  use Ecto.Migration

  def change do
    create table(:product_collections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :code, :string
      add :status, :string, null: false
      add :name, :string, null: false
      add :label, :string
      add :sort_index, :integer

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:product_collections, [:account_id, :code], where: "code IS NOT NULL")
    create index(:product_collections, [:account_id, :name])
    create index(:product_collections, [:account_id, :label])
    create index(:product_collections, [:account_id, :status])
  end
end