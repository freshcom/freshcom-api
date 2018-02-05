defmodule BlueJet.Repo.Migrations.CreatePointDeposit do
  use Ecto.Migration

  def change do
    create table(:depositables, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :avatar_id, references(:files, type: :binary_id, on_delete: :nilify_all)

      add :status, :string, null: false
      add :code, :string
      add :name, :string, null: false
      add :label, :string

      add :print_name, :string
      add :amount, :integer
      add :target_type, :string, null: false

      add :caption, :string
      add :description, :string
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create unique_index(:depositables, [:account_id, :code], where: "code IS NOT NULL")
    create index(:depositables, [:account_id, :status])
    create index(:depositables, [:account_id, :name])
    create index(:depositables, [:account_id, :label], where: "label IS NOT NULL")
  end
end