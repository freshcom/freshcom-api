defmodule BlueJet.Identity.AccountMembership.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.Identity.{Account, User, AccountMembership}

  def filterable_fields, do: [:id, :role, :user_id, :account_id]
  def identifiable_fields, do: [:id, :user_id, :account_id]

  def default() do
    from(am in AccountMembership)
  end

  def get_by(q, i), do: filter_by(q, i, identifiable_fields())

  def filter_by(q, f), do: filter_by(q, f, filterable_fields())

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

  def search(q, k, _, _), do: search(q, k)

  def preloads({:account, _}, _) do
    [account: Account.Query.default()]
  end

  def preloads({:user, _}, _) do
    [user: User.Query.default()]
  end
end
