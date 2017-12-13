defmodule BlueJet.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string

      add :default_locale, :string, null: false, default: "en"
      add :live_account_id, references(:accounts, type: :binary_id)
      add :mode, :string, null: false, default: "live"

      timestamps()
    end

  end
end
