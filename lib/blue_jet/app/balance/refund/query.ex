defmodule BlueJet.Balance.Refund.Query do
  use BlueJet, :query

  use BlueJet.Query.Search,
    for: [
      :code
    ]

  use BlueJet.Query.Filter,
    for: [
      :status,
      :gateway,
      :processor,
      :method,
      :label,
      :owner_id,
      :owner_type,
      :target_id,
      :target_type
    ]

  alias BlueJet.Balance.Refund

  def default() do
    from(r in Refund)
  end
end
