defmodule BlueJet.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :stripe_user_id, :string
      add :stripe_access_token, :string
      add :stripe_refresh_token, :string
      add :stripe_publishable_key, :string
      add :stripe_livemode, :boolean
      add :stripe_scope, :string

      timestamps()
    end

  end
end
