defmodule BlueJet.Crm.PointAccount.Query do
  use BlueJet, :query

  alias BlueJet.Crm.{PointAccount, PointTransaction}

  def default() do
    from(pa in PointAccount)
  end

  def for_customer(query, customer_id) do
    from(pa in query, where: pa.customer_id == ^customer_id)
  end

  def preloads({:transactions, transaction_preloads}, options) do
    query =
      PointTransaction.Query.default()
      |> PointTransaction.Query.filter_by(%{status: "committed"})
      |> BlueJet.Query.paginate(size: 10, number: 1)

    [transactions: {query, PointTransaction.Query.preloads(transaction_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end
