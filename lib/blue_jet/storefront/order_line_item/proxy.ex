defmodule BlueJet.Storefront.OrderLineItem.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Storefront.{IdentityService, CatalogueService}

  def get_account(payment) do
    payment.account || IdentityService.get_account(payment)
  end

  def put(oli = %{ price_id: nil }, {:price, _}, _), do: oli

  def put(oli, {:price, price_path}, opts) do
    preloads = %{ path: price_path, opts: opts }
    opts = Map.take(opts, [:account, :account_id])
    price = CatalogueService.get_price(%{ id: oli.price_id, preloads: preloads }, opts)
    %{ oli | price: price }
  end

  def put(oli = %{ product_id: nil }, {:product, _}, _), do: oli

  def put(oli, {:product, product_path}, opts) do
    preloads = %{ path: product_path, opts: opts }
    opts = Map.take(opts, [:account, :account_id])
    product = CatalogueService.get_product(%{ id: oli.product_id, preloads: preloads }, opts)
    %{ oli | product: product }
  end

  def put(oli, _, _), do: oli
end