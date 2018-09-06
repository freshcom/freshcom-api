defmodule BlueJet.Storefront.OrderLineItem.Proxy do
  use BlueJet, :proxy

  alias BlueJet.{Repo, Translation}
  alias BlueJet.Storefront.{CrmService, CatalogueService, GoodsService, FulfillmentService}

  def get_goods(oli = %{ product: %{ goods_type: "Stockable", goods_id: id }}) do
    account = get_account(oli)
    GoodsService.get_stockable(%{ id: id }, %{ account: account })
  end

  def get_goods(oli = %{ product: %{ goods_type: "Unlockable", goods_id: id }}) do
    account = get_account(oli)
    GoodsService.get_unlockable(%{ id: id }, %{ account: account })
  end

  def get_goods(oli = %{ product: %{ goods_type: "Depositable", goods_id: id }}) do
    account = get_account(oli)
    GoodsService.get_depositable(%{ id: id }, %{ account: account })
  end

  def get_depositable(oli = %{ source_type: "Depositable", source_id: id }) do
    account = get_account(oli)
    GoodsService.get_depositable(%{ id: id }, %{ account: account })
  end

  def get_depositable(oli = %{ product: %{ goods_type: "Depositable", goods_id: id }}) do
    account = get_account(oli)
    GoodsService.get_depositable(%{ id: id }, %{ account: account })
  end

  def get_point_account(oli) do
    opts = get_sopts(oli)
    oli = Repo.preload(oli, :order)
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

  def create_fulfillment_item(oli, package) do
    opts =
      get_sopts(oli)
      |> Map.put(:package, package)

    translations = Translation.merge_translations(%{}, oli.translations, ["name"])

    FulfillmentService.create_fulfillment_item(%{
      package_id: package.id,
      order_id: package.order_id,
      order_line_item_id: oli.id,
      target_id: oli.target_id,
      target_type: oli.target_type,
      status: "fulfilled",
      name: oli.name,
      quantity: oli.order_quantity,
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