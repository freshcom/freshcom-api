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

  describe "query_for/1" do
    test "with product_item_id and order_quantity" do
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
        charge_cents: 100,
        order_unit: "EA",
        charge_unit: "EA"
      })
      price3 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: 100,
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
        charge_cents: 100,
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
        charge_cents: 100,
        minimum_order_quantity: 20,
        order_unit: "EA",
        charge_unit: "EA"
      })

      price = Price.query_for(product_item_id: product_item.id, order_quantity: 3)
      assert price == price3

      price = Price.query_for(product_item_id: product_item.id, order_quantity: 5)
      assert price == price3

      price = Price.query_for(product_item_id: product_item.id, order_quantity: 11)
      assert price == price8
    end

    @tag :focus
    test "with product_item_ids and order_quantity" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        status: "active",
        name: "Apple",
        account_id: account.id
      })
      product_item1 = Repo.insert!(%ProductItem{
        status: "active",
        name: "Apple Large",
        account_id: account.id,
        product_id: product.id
      })
      price1 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item1.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: 100,
        order_unit: "EA",
        charge_unit: "EA"
      })
      price3 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item1.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: 100,
        minimum_order_quantity: 3,
        order_unit: "EA",
        charge_unit: "EA"
      })
      price8 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item1.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: 100,
        minimum_order_quantity: 8,
        order_unit: "EA",
        charge_unit: "EA"
      })
      price20 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item1.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: 100,
        minimum_order_quantity: 20,
        order_unit: "EA",
        charge_unit: "EA"
      })

      product_item2 = Repo.insert!(%ProductItem{
        status: "active",
        account_id: account.id,
        product_id: product.id,
        name: "Apple Large"
      })
      price1 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item2.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: 100,
        order_unit: "EA",
        charge_unit: "EA"
      })
      price3 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item2.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: 100,
        minimum_order_quantity: 3,
        order_unit: "EA",
        charge_unit: "EA"
      })
      price8 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item2.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: 100,
        minimum_order_quantity: 10,
        order_unit: "EA",
        charge_unit: "EA"
      })
      price20 = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item2.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: 100,
        minimum_order_quantity: 20,
        order_unit: "EA",
        charge_unit: "EA"
      })

      prices = Price.query_for(product_item_ids: [product_item1.id, product_item2.id], order_quantity: 10) |> Repo.all()
    end
  end
end
