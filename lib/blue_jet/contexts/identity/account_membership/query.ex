defmodule BlueJet.Identity.AccountMembership.Query do
  use BlueJet, :query

  alias BlueJet.Identity.{Account, AccountMembership}

  def default() do
    from(am in AccountMembership)
  end

  def preloads(:account) do
    [account: Account.Query.default()]
  end
end
