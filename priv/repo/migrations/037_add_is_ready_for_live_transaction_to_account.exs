defmodule BlueJet.Repo.Migrations.AddIsReadyForLiveTransactionToAccount do
  use Ecto.Migration

  def change do
    alter table("accounts") do
      add :is_ready_for_live_transaction, :boolean, null: false, default: false
    end
  end
end
