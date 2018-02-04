defmodule BlueJet.Storefront.EventHandler do
  @behaviour BlueJet.EventHandler

  alias BlueJet.Repo
  alias Ecto.Changeset

  alias BlueJet.Storefront.{Order, OrderLineItem}

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

  def handle_event("distribution.fulfillment_line_item.after_create", %{ fulfillment_line_item: fli = %{ source_type: "OrderLineItem" } }) do
    oli = Repo.get!(OrderLineItem, fli.source_id)
    OrderLineItem.refresh_fulfillment_status(oli)

    {:ok, fli}
  end

  def handle_event("distribution.fulfillment_line_item.after_update", %{
    fulfillment_line_item: fli = %{ source_type: "OrderLineItem" },
    changeset: %{ changes: %{ status: status } }
  }) do
    oli = Repo.get!(OrderLineItem, fli.source_id)
    OrderLineItem.refresh_fulfillment_status(oli)

    if oli.source_type == "Unlockable" && (status == "returned" || status == "discarded") do
      unlock = Repo.get_by(Unlock, source_id: oli.id, source_type: "OrderLineItem")
      if unlock do
        Repo.delete!(unlock)
      end
    end

    {:ok, fli}
  end

  def handle_event(_, _) do
    {:ok, nil}
  end
end