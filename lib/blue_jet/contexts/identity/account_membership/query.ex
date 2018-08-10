defmodule BlueJet.Identity.AccountMembership.Query do
  use BlueJet, :query

  use BlueJet.Query.Filter, for: [
    :id,
    :role,
    :user_id,
    :account_id
  ]

  alias BlueJet.Identity.{Account, User, AccountMembership}

  def default() do
    from(am in AccountMembership)
  end

  def preloads({:account, _}, options) do
    [account: Account.Query.default()]
  end

  def preloads({:user, _}, options) do
    [user: User.Query.default()]
  end
end
