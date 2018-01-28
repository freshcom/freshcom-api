defmodule BlueJet.Repo.Migrations.CreatePointTransaction do
  use Ecto.Migration

  def change do
    create table(:point_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :point_account_id, references(:point_accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :source_id, :binary_id
      add :source_type, :string

      add :status, :string, null: false
      add :code, :string
      add :name, :string
      add :label, :string

      add :reason_label, :string
      add :amount, :integer, null: false
      add :balance_after_commit, :integer

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :committed_at, :utc_datetime

      timestamps()
    end

    create unique_index(:point_transactions, [:account_id, :code], where: "code IS NOT NULL")
    create index(:point_transactions, [:account_id, :status])
    create index(:point_transactions, [:account_id, :name])
    create index(:point_transactions, [:account_id, :label], where: "label IS NOT NULL")
    create index(:point_transactions, [:account_id, :reason_label])
    create index(:point_transactions, [:account_id, :point_account_id])
  end
end