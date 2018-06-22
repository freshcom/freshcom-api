defmodule BlueJet.DataTrading.DataImport.Query do
  use BlueJet, :query

  use BlueJet.Query.Filter,
    for: [
      :id,
      :status
    ]

  alias BlueJet.DataTrading.DataImport

  def default() do
    from(di in DataImport)
  end
end
