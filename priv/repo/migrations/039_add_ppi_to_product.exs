defmodule BlueJet.Repo.Migrations.AddPpiToProduct do
  use Ecto.Migration

  def change do
    alter table("products") do
      add :price_proportion_index, :integer, null: false
    end
  end
end
