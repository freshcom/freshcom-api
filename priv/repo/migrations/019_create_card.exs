defmodule BlueJet.Repo.Migrations.CreateCard do
  use Ecto.Migration

  def change do
    create table(:cards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false

      add :status, :string, null: false, default: "draft"
      add :last_four_digit, :string
      add :exp_month, :integer
      add :exp_year, :integer
      add :fingerprint, :string
      add :cardholder_name, :string
      add :brand, :string
      add :primary, :boolean, null: false, default: false

      add :stripe_card_id, :string
      add :string_customer_id, :string
      add :owner_id, :binary_id
      add :owner_type, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end

    create index(:cards, [:account_id])
    create unique_index(:cards, [:owner_id, :owner_type, :fingerprint])
  end
end