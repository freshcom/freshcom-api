defmodule BlueJet.Repo.Migrations.CreateFulfillment do
  use Ecto.Migration

  def change do
    create table(:fulfillments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :code, :string
      add :name, :string
      add :label, :string

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :source_id, :binary_id
      add :source_type, :string

      timestamps()
    end

    create unique_index(:fulfillments, [:account_id, :code], where: "code IS NOT NULL")
    create index(:fulfillments, :account_id)
    create index(:fulfillments, [:account_id, :status])
    create index(:fulfillments, [:account_id, :name])
    create index(:fulfillments, [:account_id, :label])
  end
end
