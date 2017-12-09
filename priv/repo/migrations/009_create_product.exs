defmodule BlueJet.Repo.Migrations.CreateProduct do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :code, :string
      add :kind, :string, null: false, default: "simple"
      add :status, :string, null: false

      add :name_sync, :string, null: false, default: "disabled"
      add :name, :string, null: false
      add :short_name, :string
      add :print_name, :string

      add :sort_index, :integer
      add :source_quantity, :integer, null: false
      add :primary, :boolean, null: false, default: false
      add :maximum_public_order_quantity, :integer

      add :caption, :string
      add :description, :string

      add :source_id, :binary_id
      add :source_type, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :avatar_id, references(:external_files, type: :binary_id, on_delete: :nilify_all)
      add :parent_id, references(:products, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:products, [:account_id, :code], where: "code IS NOT NULL")
    create unique_index(:products, [:account_id, :print_name])
    create index(:products, [:account_id, :name])
    create index(:products, [:account_id, :status])
  end
end
