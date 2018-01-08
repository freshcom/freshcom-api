defmodule BlueJet.Repo.Migrations.CreateFulfillment do
  use Ecto.Migration

  def change do
    create table(:fulfillments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
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
    create index(:fulfillments, [:account_id, :name])
    create index(:fulfillments, [:account_id, :label], where: "label IS NOT NULL")
    create index(:fulfillments, [:account_id, :source_id, :source_type], where: "source_id IS NOT NULL")
  end
end
