defmodule BlueJet.Identity.Password.Query do
  use BlueJet, :query

  alias BlueJet.Identity.{Password}

  def default() do
    from(p in Password)
  end

  def standard(query) do
    from(p in query, where: is_nil(p.account_id))
  end
end
