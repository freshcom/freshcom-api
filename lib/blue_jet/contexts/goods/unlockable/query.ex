defmodule BlueJet.Goods.Unlockable.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
    :code,
    :name,
  ]
  use BlueJet.Query.Filter, for: [
    :id,
    :status,
    :label
  ]

  alias BlueJet.Goods.Unlockable

  def default() do
    from u in Unlockable
  end

  def preloads(_, _) do
    []
  end
end