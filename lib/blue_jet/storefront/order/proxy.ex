defmodule BlueJet.Storefront.Order.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Storefront.{IdentityService, CrmService, FulfillmentService, BalanceService}
  alias BlueJet.Storefront.OrderLineItem

  def get_account(order) do
    order.account || IdentityService.get_account(order)
  end

  def put_account(order) do
    %{ order | account: get_account(order) }
  end

  def get_customer(%{ customer_id: nil }), do: nil

  def get_customer(order) do
    opts = get_sopts(order)
    order.customer || CrmService.get_customer(%{ id: order.customer_id }, opts)
  end

  def put_customer(order) do
    %{ order | customer: get_customer(order) }
  end

  def count_payment(order) do
    opts = get_sopts(order)
    BalanceService.count_payment(%{ filter: %{ target_type: "Order", target_id: order.id } }, opts)
  end

  def list_payment(order) do
    opts = get_sopts(order)
    BalanceService.list_payment(%{ filter: %{ target_type: "Order", target_id: order.id } }, opts)
  end

  def create_auto_fulfillment_package(order) do
    opts = get_sopts(order)

    {:ok, fulfillment} = FulfillmentService.create_fulfillment_package(%{
      customer_id: order.customer_id,
      order_id: order.id,
      system_label: "auto"
    }, opts)

    fulfillment
  end

  def put(order = %{ customer_id: nil }, {:customer, _}, _), do: order

  def put(order, {:customer, customer_path}, opts) do
    preloads = %{ path: customer_path, opts: opts }
    opts =
      opts
      |> Map.take([:account, :account_id])
      |> Map.merge(%{ preloads: preloads })

    customer = CrmService.get_customer(%{ id: order.customer_id }, opts)
    %{ order | customer: customer }
  end

  def put(order, {:root_line_items, rli_path}, filters) do
    root_line_items = OrderLineItem.Proxy.put(order.root_line_items, rli_path, filters)
    %{ order | root_line_items: root_line_items }
  end
end