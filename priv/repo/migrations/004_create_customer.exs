defmodule BlueJet.Repo.Migrations.CreateCustomer do
  use Ecto.Migration

  def change do
    create table(:customers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id)
      add :code, :string
      add :status, :string
      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :encrypted_password, :string
      add :label, :string
      add :display_name, :string
      add :phone_number, :string

      add :delivery_address_line_one, :string
      add :delivery_address_line_two, :string
      add :delivery_address_province, :string
      add :delivery_address_city, :string
      add :delivery_address_country_code, :string
      add :delivery_address_postal_code, :string

      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      timestamps()
    end
    create unique_index(:customers, [:account_id, :code], where: "code IS NOT NULL")
    create unique_index(:customers, [:email, :account_id])
    create index(:customers, :code)
    create index(:customers, :status)
    create index(:customers, :label)
  end
end
