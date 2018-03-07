defmodule BlueJet.Identity.Password.Query do
  use BlueJet, :query

  alias BlueJet.Identity.{Password, Account}

  def default() do
    from p in Password
  end

  def for_account(query, account_id) do
    from p in query, where: p.account_id == ^account_id
  end

  def global(query) do
    from p in query, where: is_nil(p.account_id)
  end
end