defmodule BlueJet.Repo.Migrations.CreateCard do
  use Ecto.Migration

  def change do
    create table(:cards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :code, :string
      add :name, :string
      add :label, :string

      add :last_four_digit, :string
      add :exp_month, :integer
      add :exp_year, :integer
      add :fingerprint, :string
      add :cardholder_name, :string
      add :brand, :string
      add :country, :string
      add :primary, :boolean, null: false, default: false

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :stripe_card_id, :string
      add :stripe_customer_id, :string

      add :owner_id, :binary_id
      add :owner_type, :string

      timestamps()
    end

    create unique_index(:cards, [:account_id, :code], where: "code IS NOT NULL")
    create unique_index(:cards, [:account_id, :owner_id, :owner_type, :fingerprint])
    create index(:cards, [:account_id, :status])
    create index(:cards, [:account_id, :label], where: "label IS NOT NULL")
  end
end