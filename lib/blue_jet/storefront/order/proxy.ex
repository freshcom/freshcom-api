defmodule BlueJet.Storefront.Order.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Storefront.{IdentityService, CrmService}
  alias BlueJet.Storefront.OrderLineItem

  def get_account(payment) do
    payment.account || IdentityService.get_account(payment)
  end

  def put(order = %{ customer_id: nil }, {:customer, _}, _), do: order

  def put(order, {:customer, customer_path}, opts) do
    preloads = %{ path: customer_path, opts: opts }
    opts = Map.take(opts, [:account, :account_id])
    customer = CrmService.get_customer(%{ id: order.customer_id, preloads: preloads }, opts)
    %{ order | customer: customer }
  end

  def put(order, {:root_line_items, rli_path}, filters) do
    root_line_items = OrderLineItem.Proxy.put(order.root_line_items, rli_path, filters)
    %{ order | root_line_items: root_line_items }
  end
end