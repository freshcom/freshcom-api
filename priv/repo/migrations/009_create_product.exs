defmodule BlueJet.Repo.Migrations.CreateProduct do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :parent_id, references(:products, type: :binary_id, on_delete: :delete_all)
      add :avatar_id, references(:external_files, type: :binary_id, on_delete: :nilify_all)
      add :goods_id, :binary_id
      add :goods_type, :string

      add :status, :string, null: false
      add :code, :string
      add :name, :string, null: false
      add :label, :string

      add :name_sync, :string, null: false, default: "disabled"
      add :short_name, :string
      add :print_name, :string
      add :kind, :string, null: false, default: "simple"

      add :sort_index, :integer, null: false
      add :goods_quantity, :integer, null: false
      add :primary, :boolean, null: false, default: false
      add :maximum_public_order_quantity, :integer
      add :auto_fulfill, :boolean, null: false, default: false

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:products, [:account_id, :code], where: "code IS NOT NULL")
    create index(:products, [:account_id, :status])
    create index(:products, [:account_id, :name])
    create index(:products, [:account_id, :label], where: "label IS NOT NULL")
    create index(:products, [:account_id, :kind])
    create index(:products, [:account_id, :parent_id])
    create index(:products, [:account_id, :goods_id, :goods_type], where: "goods_id IS NOT NULL")
  end
end
