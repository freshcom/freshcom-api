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

  def search(query, nil), do: query
  def search(query, ""), do: query

  def search(query, keyword) do
    keyword = "%#{keyword}%"

    from(am in query,
      join: u in User,
      on: am.user_id == u.id,
      or_where: ilike(fragment("?::varchar", u.name), ^keyword),
      or_where: ilike(fragment("?::varchar", u.email), ^keyword),
      or_where: ilike(fragment("?::varchar", u.username), ^keyword)
    )
  end

  def preloads({:account, _}, _) do
    [account: Account.Query.default()]
  end

  def preloads({:user, _}, _) do
    [user: User.Query.default()]
  end
end
