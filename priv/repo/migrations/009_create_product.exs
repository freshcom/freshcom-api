defmodule BlueJet.Repo.Migrations.CreateProduct do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :name, :string, null: false
      add :print_name, :string
      add :item_mode, :string, null: false, default: "any"

      add :caption, :string
      add :description, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :avatar_id, references(:external_files, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create index(:products, [:account_id, :name])
    create index(:products, [:account_id, :status])
    create unique_index(:products, [:account_id, :print_name])
  end
end
