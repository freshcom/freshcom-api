defmodule BlueJet.Identity.User.Query do
  use BlueJet, :query

  use BlueJet.Query.Filter,
    for: [
      :code,
      :email
    ]

  alias BlueJet.Identity.{User, AccountMembership}

  def default() do
    from(u in User)
  end

  def global(query) do
    from(u in query, where: is_nil(u.account_id))
  end

  def member_of_account(query, account_id) do
    from(
      u in query,
      join: ac in AccountMembership,
      on: ac.user_id == u.id,
      where: ac.account_id == ^account_id
    )
  end
end
