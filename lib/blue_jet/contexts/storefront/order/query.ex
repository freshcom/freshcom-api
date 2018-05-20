defmodule BlueJet.Storefront.Order.Query do
  use BlueJet, :query

  alias BlueJet.Storefront.{Order, OrderLineItem}

  @searchable_fields [
    :name,
    :email,
    :phone_number,
    :code,
    :id
  ]

  @filterable_fields [
    :id,
    :status,
    :customer_id,
    :payment_status,
    :fulfillment_status
  ]

  def default() do
    from o in Order
  end

  def search(query, keyword, locale, default_locale) do
    search(query, @searchable_fields, keyword, locale, default_locale, Order.translatable_fields())
  end

  def filter_by(query, filter) do
    filter_by(query, filter, @filterable_fields)
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