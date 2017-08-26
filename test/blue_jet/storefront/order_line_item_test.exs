defmodule BlueJet.OrderLineItemTest do
  use BlueJet.DataCase

  import Money.Sigils

  alias BlueJet.Identity.Account
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.Storefront.Price
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Product
  alias BlueJet.Inventory.Sku

  describe "schema" do
    test "defaults" do
      struct = %Product{}

      assert struct.item_mode == "any"
      assert struct.custom_data == %{}
      assert struct.translations == %{}
    end
  end

  describe "changeset/3" do
    test "with new OrderLineItem with product_item_id" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        status: "active",
        name: "Apple",
        account_id: account.id
      })
      product_item = Repo.insert!(%ProductItem{
        status: "active",
        name: "Apple Large",
        account_id: account.id,
        product_id: product.id,
        translations: %{
          "zh-CN" => %{
            "name" => "苹果 大号"
          },
          "lala" => %{
            "name" => "LOL Apple Large"
          }
        }
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: %Money{ amount: 1000, currency: :CAD },
        order_unit: "EA",
        charge_unit: "EA",
        translations: %{
          "zh-CN" => %{
            "name" => "原价"
          },
          "lala" => %{
            "name" => "LOL Regular Price"
          }
        }
      })
      end_time = Timex.shift(Timex.now(), days: 3)
      bulk_price = Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item.id,
        status: "active",
        caption: "Bulk price is good",
        label: "blulk",
        name: "Bulk Price",
        charge_cents: %Money{ amount: 899, currency: :CAD },
        order_unit: "EA",
        charge_unit: "EA",
        minimum_order_quantity: 3,
        tax_one_rate: 5,
        tax_two_rate: 7,
        tax_three_rate: 1,
        end_time: end_time,
        translations: %{
          "zh-CN" => %{
            "name" => "团购价"
          },
          "lala" => %{
            "name" => "LOL Bulk Price"
          }
        }
      })
      order = Repo.insert!(%Order{ account_id: account.id })

      changeset = OrderLineItem.changeset(%OrderLineItem{}, %{
        "account_id" => account.id,
        "order_id" => order.id,
        "product_item_id" => product_item.id,
        "order_quantity" => 3
      })

      correct_translations = %{
        "zh-CN" => %{
          "name" => "苹果 大号",
          "price_name" => "团购价"
        },
        "lala" => %{
          "name" => "LOL Apple Large",
          "price_name" => "LOL Bulk Price"
        }
      }

      assert changeset.changes.name == product_item.name
      assert changeset.changes.price_label == bulk_price.label
      assert changeset.changes.price_caption == bulk_price.caption
      assert changeset.changes.price_id == bulk_price.id
      assert changeset.changes.price_name == bulk_price.name
      assert changeset.changes.price_charge_cents == bulk_price.charge_cents
      assert changeset.changes.price_charge_unit == bulk_price.charge_unit
      assert changeset.changes.price_order_unit == bulk_price.order_unit
      assert changeset.changes.price_tax_one_rate == bulk_price.tax_one_rate
      assert changeset.changes.price_tax_two_rate == bulk_price.tax_two_rate
      assert changeset.changes.price_tax_three_rate == bulk_price.tax_three_rate
      assert changeset.changes.price_estimate_by_default == bulk_price.estimate_by_default
      assert changeset.changes.price_end_time == end_time
      assert changeset.changes.order_quantity == 3
      assert changeset.changes.charge_quantity == Decimal.new(3)
      assert changeset.changes.sub_total_cents == %Money{ amount: 2697, currency: :CAD }
      assert changeset.changes.tax_one_cents == %Money{ amount: 135, currency: :CAD }
      assert changeset.changes.tax_two_cents == %Money{ amount: 189, currency: :CAD }
      assert changeset.changes.tax_three_cents == %Money{ amount: 27, currency: :CAD }
      assert changeset.changes.grand_total_cents == %Money{ amount: 3048, currency: :CAD }

      assert changeset.changes.translations == correct_translations
    end

    test "with new OrderLineItem with product_id" do
      account = Repo.insert!(%Account{})
      product = Repo.insert!(%Product{
        status: "active",
        name: "Fruit Combo",
        item_mode: "all",
        account_id: account.id,
        translations: %{
          "zh-CN" => %{
            "name" => "水果套餐"
          },
          "lala" => %{
            "name" => "LOL Fruit Combo"
          }
        }
      })
      product_item1 = Repo.insert!(%ProductItem{
        status: "active",
        name: "Apple Large",
        account_id: account.id,
        product_id: product.id,
        source_quantity: 2
      })
      price_end_time1 = Timex.shift(Timex.now(), days: 1)
      Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item1.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: %Money{ amount: 1000, currency: :CAD },
        order_unit: "EA",
        charge_unit: "EA",
        tax_one_rate: 5,
        tax_two_rate: 7,
        tax_three_rate: 1,
        end_time: price_end_time1
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item1.id,
        status: "active",
        caption: "Bulk price is good",
        label: "blulk",
        name: "Bulk Price",
        charge_cents: %Money{ amount: 899, currency: :CAD },
        order_unit: "EA",
        charge_unit: "EA",
        minimum_order_quantity: 4,
        tax_one_rate: 5,
        tax_two_rate: 7,
        tax_three_rate: 1,
        end_time: price_end_time1
      })

      product_item2 = Repo.insert!(%ProductItem{
        status: "active",
        name: "Orange Large",
        account_id: account.id,
        product_id: product.id
      })
      price_end_time2 = Timex.shift(Timex.now(), days: 2)
      Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item2.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: %Money{ amount: 1000, currency: :CAD },
        order_unit: "EA",
        charge_unit: "EA",
        end_time: price_end_time2
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item2.id,
        status: "active",
        caption: "Bulk price is good",
        label: "blulk",
        name: "Bulk Price",
        charge_cents: %Money{ amount: 899, currency: :CAD },
        order_unit: "EA",
        charge_unit: "EA",
        minimum_order_quantity: 3,
        end_time: price_end_time2
      })

      order = Repo.insert!(%Order{ account_id: account.id })

      changeset = OrderLineItem.changeset(%OrderLineItem{}, %{
        "account_id" => account.id,
        "order_id" => order.id,
        "product_id" => product.id,
        "order_quantity" => 1
      })

      correct_translations = %{
        "zh-CN" => %{
          "name" => "水果套餐"
        },
        "lala" => %{
          "name" => "LOL Fruit Combo"
        }
      }

      assert changeset.changes.name == product.name
      assert changeset.changes.price_end_time == price_end_time1
      assert changeset.changes.order_quantity == 1
      assert changeset.changes.charge_quantity == Decimal.new(1)
      assert changeset.changes.sub_total_cents == ~M[2000]
      assert changeset.changes.tax_one_cents == ~M[50]
      assert changeset.changes.tax_two_cents == ~M[70]
      assert changeset.changes.tax_three_cents == ~M[10]
      assert changeset.changes.grand_total_cents == ~M[2130]
      assert changeset.changes.translations == correct_translations

      changeset = OrderLineItem.changeset(%OrderLineItem{}, %{
        "account_id" => account.id,
        "order_id" => order.id,
        "product_id" => product.id,
        "order_quantity" => 3
      })

      assert changeset.changes.name == product.name
      assert changeset.changes.price_end_time == price_end_time1
      assert changeset.changes.order_quantity == 3
      assert changeset.changes.charge_quantity == Decimal.new(3)
      assert changeset.changes.sub_total_cents == ~M[5697]
      assert changeset.changes.tax_one_cents == ~M[150]
      assert changeset.changes.tax_two_cents == ~M[210]
      assert changeset.changes.tax_three_cents == ~M[30]
      assert changeset.changes.grand_total_cents == ~M[6087]
      assert changeset.changes.translations == correct_translations
    end
  end

  describe "balance!/1" do
    test "with custom OrderLineItem" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        name: "Custom Line",
        is_leaf: true,
        parent_id: nil,
        order_id: order.id,
        order_quantity: 1,
        charge_quantity: 1,
        sub_total_cents: 0,
        tax_one_cents: 0,
        tax_two_cents: 0,
        tax_three_cents: 0,
        grand_total_cents: 0
      })

      OrderLineItem.balance!(item)
      children = Ecto.assoc(item, :children) |> Repo.all()

      assert length(children) == 0
    end

    test "with OrderLineItem with ProductItem" do
      account = Repo.insert!(%Account{})
      sku = Repo.insert!(%Sku{
        account_id: account.id,
        status: "active",
        name: "Apple",
        print_name: "APPLED",
        unit_of_measure: "EA"
      })
      product = Repo.insert!(%Product{
        status: "active",
        name: "Apple",
        account_id: account.id
      })
      product_item = Repo.insert!(%ProductItem{
        status: "active",
        account_id: account.id,
        product_id: product.id,
        sku_id: sku.id,
        name: "Apple",
        source_quantity: 5
      })
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      order_line_item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        is_leaf: false,
        parent_id: nil,
        order_id: order.id,
        charge_quantity: 3,
        order_quantity: 3,
        product_item_id: product_item.id,
        sub_total_cents: ~M[1000],
        tax_one_cents: ~M[20],
        tax_two_cents: ~M[10],
        tax_three_cents: ~M[60],
        grand_total_cents: ~M[1090]
      })

      children = order_line_item |> OrderLineItem.balance!() |> OrderLineItem.balance!() |> Ecto.assoc(:children) |> Repo.all()
      child = Enum.at(children, 0)

      assert length(children) == 1
      assert child.order_quantity == 15
      assert child.charge_quantity == Decimal.new(15)
      assert child.sub_total_cents == order_line_item.sub_total_cents
      assert child.tax_one_cents == order_line_item.tax_one_cents
      assert child.tax_two_cents == order_line_item.tax_two_cents
      assert child.tax_three_cents == order_line_item.tax_three_cents
      assert child.grand_total_cents == order_line_item.grand_total_cents
      assert child.is_leaf
      assert child.sku_id == product_item.sku_id
    end

    test "with OrderLineItem with Product" do
      account = Repo.insert!(%Account{})
      sku1 = Repo.insert!(%Sku{
        account_id: account.id,
        status: "active",
        name: "Apple",
        print_name: "APPLED",
        unit_of_measure: "EA"
      })
      sku2 = Repo.insert!(%Sku{
        account_id: account.id,
        status: "active",
        name: "Orange",
        print_name: "ORANGE",
        unit_of_measure: "EA"
      })
      product = Repo.insert!(%Product{
        status: "active",
        name: "Fruit Combo",
        item_mode: "any",
        account_id: account.id
      })
      product_item1 = Repo.insert!(%ProductItem{
        status: "active",
        account_id: account.id,
        product_id: product.id,
        sku_id: sku1.id,
        name: "Apple",
        source_quantity: 5
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item1.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: %Money{ amount: 1000, currency: :CAD },
        order_unit: "EA",
        charge_unit: "EA"
      })
      product_item2 = Repo.insert!(%ProductItem{
        status: "active",
        account_id: account.id,
        product_id: product.id,
        sku_id: sku2.id,
        name: "Orange",
        source_quantity: 3
      })
      Repo.insert!(%Price{
        account_id: account.id,
        product_item_id: product_item2.id,
        status: "active",
        label: "regular",
        name: "Regular Price",
        charge_cents: %Money{ amount: 1000, currency: :CAD },
        order_unit: "EA",
        charge_unit: "EA"
      })
      order = Repo.insert!(%Order{
        account_id: account.id
      })
      order_line_item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        name: product.name,
        is_leaf: false,
        parent_id: nil,
        order_id: order.id,
        charge_quantity: 3,
        order_quantity: 3,
        product_id: product.id,
        sub_total_cents: ~M[6000],
        tax_one_cents: ~M[0],
        tax_two_cents: ~M[0],
        tax_three_cents: ~M[0],
        grand_total_cents: ~M[6000]
      })

      children =
        order_line_item
        |> OrderLineItem.balance!()
        |> OrderLineItem.balance!()
        |> Ecto.assoc(:children)
        |> Repo.all()
      child1 = Enum.at(children, 0)
      child2 = Enum.at(children, 1)

      assert length(children) == 2
      assert child1.order_quantity == 3
      assert child1.sub_total_cents == ~M[3000]
      assert child2.order_quantity == 3
      assert child2.sub_total_cents == ~M[3000]


      # IO.inspect "#{order_line_item.name} x #{order_line_item.order_quantity} #{order_line_item.grand_total_cents}"
      # Enum.each(children, fn(child) ->
      #   IO.inspect "- #{child.name} x #{child.order_quantity} #{child.grand_total_cents}"
      #   grandchildren = Ecto.assoc(child, :children) |> Repo.all()

      #   Enum.each(grandchildren, fn(grandchild) ->
      #     IO.inspect "-- #{grandchild.name} x #{grandchild.order_quantity} #{child.grand_total_cents}"
      #   end)
      # end)

      # assert child.order_quantity == 15
      # assert child.charge_quantity == Decimal.new(15)
      # assert child.sub_total_cents == order_line_item.sub_total_cents
      # assert child.tax_one_cents == order_line_item.tax_one_cents
      # assert child.tax_two_cents == order_line_item.tax_two_cents
      # assert child.tax_three_cents == order_line_item.tax_three_cents
      # assert child.grand_total_cents == order_line_item.grand_total_cents
      # assert child.is_leaf
      # assert child.sku_id == product_item.sku_id
    end
  end
end
