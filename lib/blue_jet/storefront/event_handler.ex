defmodule BlueJet.Storefront.EventHandler do
  @behaviour BlueJet.EventHandler

  alias BlueJet.Repo
  alias Ecto.Changeset

  alias BlueJet.Storefront.{Order, OrderLineItem, Unlock}

  def handle_event("balance.payment.after_create", %{ payment: %{ target_type: "Order", target_id: order_id } }) do
    order = Repo.get!(Order, order_id)

    case order.status do
      "cart" ->
        changeset =
          order
          |> Order.refresh_payment_status()
          |> Changeset.change(status: "opened", opened_at: Ecto.DateTime.utc())
          |> Map.put(:action, :update)

        changeset
        |> Repo.update!()
        |> Order.process(changeset)
      _ ->
        {:ok, Order.refresh_payment_status(order)}
    end
  end

  def handle_event("balance.payment.after_update", %{ payment: %{ target_type: "Order", target_id: order_id } }) do
    order =
      Repo.get!(Order, order_id)
      |> Order.refresh_payment_status()

    {:ok, order}
  end

  def handle_event("balance.refund.after_create", %{ refund: %{ target_type: "Order", target_id: order_id } }) do
    order =
      Repo.get!(Order, order_id)
      |> Order.refresh_payment_status()

    {:ok, order}
  end

  def handle_event("fulfillment.fulfillment_item.after_create", %{
    fulfillment_item: fulfillment_item = %{ status: "fulfilled" }
  }) do
    oli = Repo.get!(OrderLineItem, fulfillment_item.order_line_item_id)
    OrderLineItem.refresh_fulfillment_status(oli)

    {:ok, nil}
  end

  def handle_event("fulfillment.fulfillment_item.after_update", %{
    fulfillment_item: fulfillment_item,
    changeset: %{ changes: %{ status: _ } }
  }) do
    oli = Repo.get!(OrderLineItem, fulfillment_item.order_line_item_id)
    OrderLineItem.refresh_fulfillment_status(oli)

    {:ok, nil}
  end

  def handle_event(_, _) do
    {:ok, nil}
  end
end