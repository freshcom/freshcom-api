defmodule BlueJet.Catalogue.PriceTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Catalogue.Price
  alias BlueJet.Catalogue.Product

  describe "schema" do
    test "defaults" do
      price = %Price{}

      assert price.status == "draft"
      assert price.currency_code == "CAD"
      assert price.estimate_by_default == false
      assert price.minimum_order_quantity == 1
      assert price.tax_one_percentage == Decimal.new(0)
      assert price.tax_two_percentage == Decimal.new(0)
      assert price.tax_three_percentage == Decimal.new(0)
      assert price.custom_data == %{}
      assert price.translations == %{}
    end

    test "when product is deleted price should be automatically deleted" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      price = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })

      Repo.delete!(product)
      refute Repo.get(Price, price.id)
    end

    test "when parent is deleted price should be automatically deleted" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      parent = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })
      price = Repo.insert!(%Price{
        account_id: account.id,
        product_id: product.id,
        parent_id: parent.id,
        name: Faker.String.base64(5),
        charge_amount_cents: 500,
        charge_unit: Faker.String.base64(2),
        order_unit: Faker.String.base64(2)
      })

      Repo.delete!(parent)
      refute Repo.get(Price, price.id)
    end
  end

  test "writable_fields/0" do
    assert Price.writable_fields() == [
      :status,
      :code,
      :name,
      :label,
      :currency_code,
      :charge_amount_cents,
      :charge_unit,
      :order_unit,
      :estimate_by_default,
      :estimate_average_percentage,
      :estimate_maximum_percentage,
      :minimum_order_quantity,
      :tax_one_percentage,
      :tax_two_percentage,
      :tax_three_percentage,
      :start_time,
      :end_time,
      :caption,
      :description,
      :custom_data,
      :product_id,
      :parent_id
    ]
  end

  describe "validate/1" do
    test "when given price missing required fields" do
      changeset =
        change(%Price{}, %{})
        |> Price.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :product_id, :charge_amount_cents, :charge_unit]
    end
  end

#   describe "query_for/1" do
#     test "with product_item_id and order_quantity" do
#       account = Repo.insert!(%Account{})
#       product = Repo.insert!(%Product{
#         status: "active",
#         name: "Apple",
#         account_id: account.id
#       })
#       product_item = Repo.insert!(%ProductItem{
#         status: "active",
#         name: "Apple",
#         account_id: account.id,
#         product_id: product.id
#       })
#       Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: 100,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })
#       price3 = Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: ~M[100],
#         minimum_order_quantity: 3,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })
#       price8 = Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: ~M[100],
#         minimum_order_quantity: 8,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })
#       Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: 100,
#         minimum_order_quantity: 20,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })

#       price = Price.query_for(product_item_id: product_item.id, order_quantity: 3) |> Repo.one()
#       assert price == price3

#       price = Price.query_for(product_item_id: product_item.id, order_quantity: 5) |> Repo.one()
#       assert price == price3

#       price = Price.query_for(product_item_id: product_item.id, order_quantity: 11) |> Repo.one()
#       assert price == price8
#     end

#     test "with product_item_ids and order_quantity" do
#       account = Repo.insert!(%Account{})
#       product = Repo.insert!(%Product{
#         status: "active",
#         name: "Apple",
#         account_id: account.id
#       })
#       product_item1 = Repo.insert!(%ProductItem{
#         status: "active",
#         name: "Apple Large",
#         account_id: account.id,
#         product_id: product.id
#       })
#       Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item1.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: 100,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })
#       Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item1.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: 100,
#         minimum_order_quantity: 3,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })
#       target_price1 = Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item1.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: ~M[100],
#         minimum_order_quantity: 8,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })
#       Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item1.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: 100,
#         minimum_order_quantity: 20,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })

#       product_item2 = Repo.insert!(%ProductItem{
#         status: "active",
#         account_id: account.id,
#         product_id: product.id,
#         name: "Apple Large"
#       })
#       Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item2.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: 100,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })
#       Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item2.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: 100,
#         minimum_order_quantity: 3,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })
#       target_price2 = Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item2.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: ~M[100],
#         minimum_order_quantity: 10,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })
#       Repo.insert!(%Price{
#         account_id: account.id,
#         product_item_id: product_item2.id,
#         status: "active",
#         label: "regular",
#         name: "Regular Price",
#         charge_amount_cents: 100,
#         minimum_order_quantity: 20,
#         order_unit: "EA",
#         charge_unit: "EA"
#       })

#       prices = Price.query_for(product_item_ids: [product_item1.id, product_item2.id], order_quantity: 10) |> Repo.all()
#       assert length(prices) == 2
#       assert prices -- [target_price1, target_price2] == []
#     end
#  end
end
