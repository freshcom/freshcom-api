defmodule BlueJet.Repo.Migrations.CreateFulfillmentPackage do
  use Ecto.Migration

  def change do
    create table(:fulfillment_packages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :customer_id, references(:customers, type: :binary_id, on_delete: :nilify_all)
      add :order_id, references(:orders, type: :binary_id, on_delete: :nilify_all), null: false

      add :system_label, :string

      add :status, :string, null: false
      add :code, :string
      add :name, :string
      add :label, :string

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:fulfillment_packages, [:account_id, :code], where: "code IS NOT NULL")
    create index(:fulfillment_packages, [:account_id, :system_label])
    create index(:fulfillment_packages, [:account_id, :order_id])
    create index(:fulfillment_packages, [:account_id, :name])
    create index(:fulfillment_packages, [:account_id, :label], where: "label IS NOT NULL")
  end
end
