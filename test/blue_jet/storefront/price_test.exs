defmodule BlueJet.PriceTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.Storefront.Price
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Product

  describe "schema" do
    test "defaults" do
      struct = %Product{}

      assert struct.item_mode == "any"
      assert struct.custom_data == %{}
      assert struct.translations == %{}
    end
  end

  describe "for/1" do
    @tag :focus
    test "" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        status: "active",
        name: "Apple",
        account_id: account.id
      })
      product_item = Repo.insert!(%ProductItem{
        status: "active",
        account_id: account.id,
        product_id: product.id
      })
      price1 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_amount_cents: 100,
        order_unit: "EA",
        charge_unit: "EA"
      })
      price3 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_amount_cents: 100,
        minimum_order_quantity: 3,
        order_unit: "EA",
        charge_unit: "EA"
      })
      price8 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_amount_cents: 100,
        minimum_order_quantity: 8,
        order_unit: "EA",
        charge_unit: "EA"
      })
      price20 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_amount_cents: 100,
        minimum_order_quantity: 20,
        order_unit: "EA",
        charge_unit: "EA"
      })

      price = Price.for(product_item_id: product_item.id, order_quantity: 3)
      assert price == price3

      price = Price.for(product_item_id: product_item.id, order_quantity: 5)
      assert price == price3

      price = Price.for(product_item_id: product_item.id, order_quantity: 11)
      assert price == price8
    end
  end
end
