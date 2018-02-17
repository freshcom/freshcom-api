defmodule BlueJet.Identity.User.Query do
  use BlueJet, :query

  alias BlueJet.Identity.User
  alias BlueJet.Identity.AccountMembership

  @filterable_fields [
    :code,
    :email
  ]

  def default() do
    from(u in User, order_by: [desc: :inserted_at])
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
  end

  def global(query) do
    from u in query, where: is_nil(u.account_id)
  end

  def for_account(query, nil) do
    from u in query, where: is_nil(u.account_id)
  end

  def for_account(query, account_id) do
    from u in query, where: u.account_id == ^account_id
  end

  def member_of_account(query, account_id) do
    from u in query,
      join: ac in AccountMembership, on: ac.user_id == u.id,
      where: ac.account_id == ^account_id
  end
end