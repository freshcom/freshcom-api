defmodule BlueJet.Storefront.Order.Query do
  use BlueJet, :query
  use BlueJet.Query.Search, for: [
    :name,
    :email,
    :phone_number,
    :code,
    :id
  ]
  use BlueJet.Query.Filter, for: [
    :id,
    :status,
    :customer_id,
    :payment_status,
    :fulfillment_status
  ]

  alias BlueJet.Storefront.{Order, OrderLineItem}

  def default() do
    from o in Order
  end

  def preloads({:root_line_items, root_line_item_preloads}, options) do
    query =
    OrderLineItem.Query.root()
    |> order_by([desc: :sort_index, asc: :inserted_at])

    [root_line_items: {query, OrderLineItem.Query.preloads(root_line_item_preloads, options)}]
  end

  def preloads(_, _) do
    []
  end
end