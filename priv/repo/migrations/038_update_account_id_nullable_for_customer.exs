defmodule BlueJet.Repo.Migrations.UpdateAccountIdNullableForCustomer do
  use Ecto.Migration

  def change do
    drop constraint("customers", "customers_account_id_fkey")

    alter table("customers") do
      modify :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: false
    end
  end
end
