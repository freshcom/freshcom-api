defmodule BlueJet.Identity.AccountMembership.Query do
  use BlueJet, :query

  alias BlueJet.Identity.{Account, AccountMembership}

  def default() do
    from am in AccountMembership
  end

  def for_account(query, account_id) do
    from am in query, where: am.account_id == ^account_id
  end

  def preloads(:account) do
    [account: Account.Query.default()]
  end
end