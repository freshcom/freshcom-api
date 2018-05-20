defmodule BlueJet.Crm.PointAccount.Query do
  use BlueJet, :query

  alias BlueJet.Crm.{PointAccount, PointTransaction}

  def for_customer(query, customer_id) do
    from pa in query, where: pa.customer_id == ^customer_id
  end

  def preloads({:transactions, transaction_preloads}, options) do
    query =
      PointTransaction.Query.default()
      |> PointTransaction.Query.committed()
      |> PointTransaction.Query.only(10)

    [transactions: {query, PointTransaction.Query.preloads(transaction_preloads, options)}]
  end
  def preloads(_, _) do
    []
  end

  def default() do
    from(pa in PointAccount, order_by: [desc: pa.updated_at])
  end
end