defmodule BlueJet.Repo.Migrations.AddIsOwnerToAccountMembership do
  use Ecto.Migration

  def change do
    alter table("account_memberships") do
      add :is_owner, :boolean, null: false, default: false
    end

    flush()
    BlueJet.Repo.update_all(BlueJet.Identity.AccountMembership, set: [is_owner: true])
  end
end
