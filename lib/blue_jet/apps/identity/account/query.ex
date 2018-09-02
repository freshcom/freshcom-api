defmodule BlueJet.Identity.Account.Query do
  use BlueJet, :query

  alias BlueJet.Identity.{Account, AccountMembership}

  def default() do
    from(a in Account)
  end

  def has_member(query, user_id) do
    from(
      a in query,
      join: ac in AccountMembership,
      on: ac.account_id == a.id,
      where: ac.user_id == ^user_id
    )
  end

  def live(query) do
    from(a in query, where: a.mode == "live")
  end
end
