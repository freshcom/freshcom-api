defmodule BlueJet.Goods.Stockable.Query do
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

  alias BlueJet.Goods.Stockable

  def default() do
    from s in Stockable
  end

  def preloads(_, _) do
    []
  end
end