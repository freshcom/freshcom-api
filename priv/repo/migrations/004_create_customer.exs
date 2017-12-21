defmodule BlueJet.Repo.Migrations.CreateCustomer do
  use Ecto.Migration

  def change do
    create table(:customers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id)
      add :status, :string, null: false
      add :code, :string
      add :name, :string, null: false
      add :label, :string

      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :phone_number, :string

      add :delivery_address_line_one, :string
      add :delivery_address_line_two, :string
      add :delivery_address_province, :string
      add :delivery_address_city, :string
      add :delivery_address_country_code, :string
      add :delivery_address_postal_code, :string

      add :caption, :string
      add :description, :text
      add :custom_data, :map, null: false, default: "{}"
      add :translations, :map, null: false, default: "{}"

      add :stripe_customer_id, :string
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :sponsor_id, references(:customers, type: :binary_id)
      add :enroller_id, references(:customers, type: :binary_id)

      timestamps()
    end

    create unique_index(:customers, [:account_id, :code], where: "code IS NOT NULL")
    create unique_index(:customers, [:account_id, :status, :email], where: "status != 'deleted'")
    create unique_index(:customers, :user_id, where: "user_id IS NOT NULL")
    create index(:customers, :status)
    create index(:customers, :name)
    create index(:customers, :label)
  end
end
