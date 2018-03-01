defmodule BlueJet.Identity.AccountMembership.Query do
  use BlueJet, :query

  alias BlueJet.Identity.{Account, AccountMembership}

  def default() do
    from am in AccountMembership, order_by: [desc: :inserted_at]
  end

  def preloads(:account) do
    [account: Account.Query.default()]
  end
end