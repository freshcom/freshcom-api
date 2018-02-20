defmodule BlueJet.Storefront.EventHandler do
  use BlueJet.EventEmitter, namespace: :storefront

  alias BlueJet.Repo
  alias Ecto.Changeset
  alias BlueJet.Storefront.{Order, OrderLineItem}

  @behaviour BlueJet.EventHandler

  def handle_event("balance.payment.create.success", %{ account: account, payment: %{ target_type: "Order", target_id: order_id } }) do
    order =
      Repo.get!(Order, order_id)
      |> Map.put(:account, account)

    case order.status do
      "cart" ->
        changeset =
          order
          |> Order.refresh_payment_status()
          |> Changeset.change(status: "opened", opened_at: Ecto.DateTime.utc())
          |> Map.put(:action, :update)

        {:ok, order} =
          changeset
          |> Repo.update!()
          |> Order.process(changeset)

        root_line_items =
          OrderLineItem.Query.default()
          |> OrderLineItem.Query.for_order(order.id)
          |> OrderLineItem.Query.root()
          |> Repo.all()

        order = %{ order | root_line_items: root_line_items }
        emit_event("storefront.order.opened.success", %{ order: order, account: account })

      _ ->
        {:ok, Order.refresh_payment_status(order)}
    end
  end

  def handle_event("balance.payment.update.success", %{ account: account, payment: %{ target_type: "Order", target_id: order_id } }) do
    order =
      Repo.get!(Order, order_id)
      |> Map.put(:account, account)
      |> Order.refresh_payment_status()

    {:ok, order}
  end

  def handle_event("balance.refund.create.success", %{ refund: %{ target_type: "Order", target_id: order_id } }) do
    order =
      Repo.get!(Order, order_id)
      |> Order.refresh_payment_status()

    {:ok, order}
  end

  def handle_event("fulfillment.fulfillment_item.create.success", %{
    fulfillment_item: fulfillment_item = %{ status: "fulfilled" }
  }) do
    oli = Repo.get!(OrderLineItem, fulfillment_item.order_line_item_id)
    OrderLineItem.refresh_fulfillment_status(oli)

    {:ok, nil}
  end

  def handle_event("fulfillment.fulfillment_item.update.success", %{
    fulfillment_item: fulfillment_item,
    changeset: %{ changes: %{ status: _ } }
  }) do
    oli = Repo.get!(OrderLineItem, fulfillment_item.order_line_item_id)
    OrderLineItem.refresh_fulfillment_status(oli)

    {:ok, nil}
  end

  def handle_event("fulfillment.fulfillment_package.delete.success", %{
    fulfillment_package: fulfillment_package
  }) do
    leaf_line_items =
      OrderLineItem.Query.default()
      |> OrderLineItem.Query.for_order(fulfillment_package.order_id)
      |> OrderLineItem.Query.leaf()
      |> Repo.all()

    Enum.each(leaf_line_items, fn(item) ->
      OrderLineItem.refresh_fulfillment_status(item)
    end)

    {:ok, nil}
  end

  def handle_event("fulfillment.return_item.create.success", %{
    return_item: return_item,
    changeset: %{ changes: %{ status: "returned" } }
  }) do
    oli = Repo.get!(OrderLineItem, return_item.order_line_item_id)
    OrderLineItem.refresh_fulfillment_status(oli)

    {:ok, nil}
  end

  def handle_event("fulfillment.return_item.update.success", %{
    return_item: return_item,
    changeset: %{ changes: %{ status: "returned" } }
  }) do
    oli = Repo.get!(OrderLineItem, return_item.order_line_item_id)
    OrderLineItem.refresh_fulfillment_status(oli)

    {:ok, nil}
  end

  def handle_event(_, _) do
    {:ok, nil}
  end
end