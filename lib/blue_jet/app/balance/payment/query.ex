defmodule BlueJet.Balance.Payment.Query do
  use BlueJet, :query

  use BlueJet.Query.Search,
    for: [
      :code
    ]

  use BlueJet.Query.Filter,
    for: [
      :id,
      :target_type,
      :target_id,
      :owner_id,
      :owner_type,
      :status,
      :gateway,
      :method,
      :label
    ]

  alias BlueJet.Balance.{Payment, Refund}

  def default() do
    from(p in Payment)
  end

  def for_target(query, target_type, target_id) do
    from(
      p in query,
      where: p.target_type == ^target_type,
      where: p.target_id == ^target_id
    )
  end

  def preloads({:refunds, refund_preloads}, options) do
    [refunds: {Refund.Query.default(), Refund.Query.preloads(refund_preloads, options)}]
  end
end
