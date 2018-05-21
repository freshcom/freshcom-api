defmodule BlueJet.Fulfillment.Unlock.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: []
  use BlueJet.Query.Filter, for: [
    :id,
    :customer_id,
    :unlockable_id
  ]

  alias BlueJet.Fulfillment.Unlock

  def default() do
    from u in Unlock
  end

  def preloads(_, _) do
    []
  end
end