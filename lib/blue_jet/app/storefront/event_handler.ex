defmodule BlueJet.Storefront.EventHandler do
  use BlueJet.EventEmitter, namespace: :storefront

  alias BlueJet.Repo
  alias Ecto.Changeset
  alias BlueJet.Storefront.{Order, OrderLineItem}
  alias BlueJet.Storefront.Service

  @behaviour BlueJet.EventHandler

  def handle_event("identity:account.reset.success", %{ account: account = %{ mode: "test" } }) do
    Task.start(fn ->
      Service.delete_all_order(%{ account: account })
    end)

    {:ok, nil}
  end

  # Before a payment is created for an order, we will mark the order as opened.
  # If the payment failed, this will be rolled back automatically.
  def handle_event("balance.payment.create.before", %{ changeset: changeset = %{ changes: %{ target_type: "Order", target_id: order_id } } }) do
    account = Changeset.get_field(changeset, :account)
    order = Service.get_order(%{ id: order_id }, %{ account: account })

    if order.status == "cart" do
      Service.update_order(order, %{ status: "opened" }, %{ account: account })
    else
      {:ok, order}
    end
  end

  def handle_event("balance.payment.create.success", %{ account: account, payment: %{ target_type: "Order", target_id: order_id } }) do
    order =
      Repo.get!(Order, order_id)
      |> Map.put(:account, account)

    {:ok, Order.refresh_payment_status(order)}
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