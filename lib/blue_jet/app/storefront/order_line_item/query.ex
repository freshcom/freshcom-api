defmodule BlueJet.Storefront.OrderLineItem.Query do
  use BlueJet, :query
  use BlueJet.Query.Filter, for: [
    :id,
    :order_id,
    :fulfillment_status
  ]

  alias BlueJet.Storefront.{Order, OrderLineItem}

  def default() do
    from oli in OrderLineItem
  end

  def for_order(query, order_id) do
    from oli in query, where: oli.order_id == ^order_id
  end

  def with_auto_fulfill(query) do
    from oli in query, where: oli.auto_fulfill == true
  end

  def root() do
    from oli in OrderLineItem, where: is_nil(oli.parent_id)
  end

  def root(query) do
    from oli in query, where: is_nil(oli.parent_id)
  end

  def leaf(query) do
    from oli in query, where: oli.is_leaf == true
  end

  def leaf_for_target_type(query, target_type) do
    from oli in query,
      where: oli.is_leaf == true,
      where: oli.target_type == ^target_type
  end

  def with_order(query, filter) do
    from oli in query,
      join: o in Order, where: oli.order_id == o.id,
      where: o.fulfillment_status == ^filter[:fulfillment_status],
      where: o.customer_id == ^filter[:customer_id]
  end

  def preloads({:order, order_preloads}, options) do
    [order: {Order.Query.default(), Order.Query.preloads(order_preloads, options)}]
  end

  def preloads({:children, children_preloads}, options) do
    [children: {OrderLineItem.Query.default(), OrderLineItem.Query.preloads(children_preloads, options)}]
  end

  def preloads(_, _), do: []
end