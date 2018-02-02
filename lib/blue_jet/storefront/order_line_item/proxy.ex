defmodule BlueJet.Storefront.OrderLineItem.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Translation
  alias BlueJet.Storefront.{CrmService, IdentityService, CatalogueService, GoodsService, DistributionService}

  def get_account(oli) do
    oli.account || IdentityService.get_account(oli)
  end

  def get_depositable(oli = %{ source_id: depositable_id, source_type: "Depositable" }) do
    opts = get_sopts(oli)
    oli.source || GoodsService.get_depositable(%{ id: depositable_id }, opts)
  end

  def get_point_account(oli) do
    opts = get_sopts(oli)
    CrmService.get_point_account(%{ customer_id: oli.order.customer_id }, opts)
  end

  def create_point_transaction(fields, oli) do
    point_account = get_point_account(oli)
    opts = get_sopts(oli)

    {:ok, pt} =
      fields
      |> Map.put(:point_account_id, point_account.id)
      |> Map.put(:source_type, "OrderLineItem")
      |> Map.put(:source_id, oli.id)
      |> CrmService.create_point_transaction(opts)

    pt
  end

  def commit_point_transaction(id, oli) do
    opts = get_sopts(oli)
    {:ok, pt} = CrmService.update_point_transaction(id, %{ status: "committed" }, opts)

    pt
  end

  def create_fulfillment_line_item(oli, fulfillment) do
    opts = get_sopts(oli)
    translations = Translation.merge_translations(%{}, oli.translations, ["name"])

    DistributionService.create_fulfillment_line_item(%{
      fulfillment_id: fulfillment.id,
      name: oli.name,
      status: "fulfilled",
      quantity: oli.order_quantity,
      source_id: oli.id,
      source_type: "OrderLineItem",
      goods_id: oli.source_id,
      goods_type: oli.source_type,
      translations: translations
    }, opts)
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