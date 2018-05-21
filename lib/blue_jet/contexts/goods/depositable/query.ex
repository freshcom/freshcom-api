defmodule BlueJet.Goods.Depositable.Query do
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

  alias BlueJet.Goods.Depositable

  def default() do
    from d in Depositable
  end

  def preloads(_, _) do
    []
  end
end