defmodule BlueJet.Repo.Migrations.CreateProduct do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :number, :string
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:products, :number)
  end
end
