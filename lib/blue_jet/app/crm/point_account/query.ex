defmodule BlueJet.CRM.PointAccount.Query do
  @behaviour BlueJet.Query

  use BlueJet, :query

  alias BlueJet.CRM.{PointAccount, PointTransaction}

  def identifiable_fields, do: [:id, :customer_id]
  def filterable_fields, do: [:id, :status]
  def searchable_fields, do: []

  def default(), do: from(pa in PointAccount)
  def get_by(q, i), do: filter_by(q, i, identifiable_fields())
  def filter_by(q, f), do: filter_by(q, f, filterable_fields())
  def search(q, k, l, d),
    do: search(q, k, l, d, searchable_fields(), [])

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

  def for_customer(query, customer_id) do
    from(pa in query, where: pa.customer_id == ^customer_id)
  end
end
