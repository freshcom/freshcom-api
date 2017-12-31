defmodule BlueJet.OrderLineItemTest do
  use BlueJet.DataCase

  alias Decimal, as: D

  alias BlueJet.Identity.Account
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.OrderLineItem
  alias BlueJet.Catalogue.Price
  alias BlueJet.Catalogue.Product
  alias BlueJet.Goods.Stockable

  def create_product_with_variants do
    account = Repo.insert!(%Account{})
    stockable = Repo.insert!(%Stockable{
      account_id: account.id,
      status: "active",
      name: "Apple",
      unit_of_measure: "EA"
    })

    product = Repo.insert!(%Product{
      status: "active",
      kind: "with_variants",
      name: "Apple",
      account_id: account.id,
      translations: %{
        "zh-CN": %{
          name: "苹果"
        }
      }
    })
    variant = Repo.insert!(%Product{
      status: "active",
      kind: "variant",
      name: "Apple Large",
      account_id: account.id,
      parent_id: product.id,
      source_type: "Stockable",
      source_id: stockable.id,
      source_quantity: 5,
      translations: %{
        "zh-CN": %{
          name: "苹果 大号"
        }
      }
    })

    %{ account: account, product: product, variant: variant }
  end

  def create_exact_regular_and_bulk_price(product, account) do
    regular_price = Repo.insert!(%Price{
      account_id: account.id,
      product_id: product.id,
      status: "active",
      name: "Regular",
      label: "regular",
      caption: "This is regular price",
      charge_amount_cents: 1000,
      order_unit: "EA",
      charge_unit: "EA",
      translations: %{
        "zh-CN": %{
          name: "原价"
        }
      }
    })
    end_time = Timex.shift(Timex.now(), days: 3)
    bulk_price = Repo.insert!(%Price{
      account_id: account.id,
      product_id: product.id,
      status: "active",
      name: "Bulk",
      label: "bulk",
      caption: "This is bulk price",
      charge_amount_cents: 899,
      order_unit: "EA",
      charge_unit: "EA",
      minimum_order_quantity: 3,
      tax_one_percentage: Decimal.new(5),
      tax_two_percentage: Decimal.new(7),
      tax_three_percentage: Decimal.new(1),
      end_time: end_time,
      translations: %{
        "zh-CN": %{
          name: "团购价"
        }
      }
    })
    %{ regular: regular_price, bulk: bulk_price }
  end

  def create_estimated_price(product, account) do
    end_time = Timex.shift(Timex.now(), days: 3)
    Repo.insert!(%Price{
      account_id: account.id,
      product_id: product.id,
      status: "active",
      name: "Regular",
      label: "regular",
      caption: "This is regular price",
      charge_amount_cents: 899,
      order_unit: "EA",
      charge_unit: "LB",
      estimate_by_default: true,
      estimate_average_percentage: 150,
      estimate_maximum_percentage: 200,
      minimum_order_quantity: 1,
      tax_one_percentage: D.new(5),
      tax_two_percentage: D.new(7),
      tax_three_percentage: D.new(1),
      end_time: end_time,
      translations: %{
        "zh-CN": %{
          name: "原价"
        }
      }
    })
  end

  def create_combo_product do

  end

  def create_regular_product_with_variable_weight do

  end

  def create_regular_product_with_unlockable do

  end

  describe "schema" do
    test "defaults" do
      oli = %OrderLineItem{}

      assert oli.fulfillment_status == "pending"
      assert oli.is_leaf
      assert oli.order_quantity == 1
      assert oli.tax_one_cents == 0
      assert oli.tax_two_cents == 0
      assert oli.tax_three_cents == 0
      assert oli.is_estimate == false
      assert oli.custom_data == %{}
      assert oli.translations == %{}
    end
  end

  describe "changeset/4" do
    test "on new order line item with product variant and exact price" do
      %{ account: account, variant: variant } = create_product_with_variants()
      %{ bulk: bulk_price } = create_exact_regular_and_bulk_price(variant, account)

      order = Repo.insert!(%Order{ account_id: account.id })
      order_quantity = 3

      changeset = OrderLineItem.changeset(%OrderLineItem{
        account_id: account.id
      }, %{
        "order_id" => order.id,
        "product_id" => variant.id,
        "order_quantity" => order_quantity
      })

      correct_translations = %{
        "zh-CN" => %{
          "name" => "苹果 大号",
          "price_name" => "团购价"
        }
      }

      assert changeset.valid?
      assert changeset.changes.name == variant.name

      assert changeset.changes.is_leaf == false
      assert changeset.changes.order_quantity == order_quantity
      assert changeset.changes.charge_quantity == D.new(order_quantity)

      assert changeset.changes.price_id == bulk_price.id
      assert changeset.changes.price_name == bulk_price.name
      assert changeset.changes.price_label == bulk_price.label
      assert changeset.changes.price_caption == bulk_price.caption
      assert changeset.changes.price_order_unit == bulk_price.order_unit
      assert changeset.changes.price_charge_unit == bulk_price.charge_unit
      assert changeset.changes.price_currency_code == bulk_price.currency_code
      assert changeset.changes.price_charge_amount_cents == bulk_price.charge_amount_cents
      assert changeset.changes.price_estimate_by_default == bulk_price.estimate_by_default
      assert changeset.changes.price_tax_one_percentage == bulk_price.tax_one_percentage
      assert changeset.changes.price_tax_two_percentage == bulk_price.tax_two_percentage
      assert changeset.changes.price_tax_three_percentage == bulk_price.tax_three_percentage
      assert changeset.changes.price_estimate_by_default == bulk_price.estimate_by_default
      assert changeset.changes.price_end_time == bulk_price.end_time

      assert changeset.changes.sub_total_cents == bulk_price.charge_amount_cents * order_quantity
      assert changeset.changes.tax_one_cents == 135
      assert changeset.changes.tax_two_cents == 189
      assert changeset.changes.tax_three_cents == 27
      assert changeset.changes.grand_total_cents == 3048
      assert changeset.changes.authorization_total_cents == 3048
      assert changeset.changes.auto_fulfill == false

      assert changeset.changes.translations == correct_translations
    end

    test "on new order line item with product variant and estimated price" do
      %{ account: account, variant: variant } = create_product_with_variants()
      estimated_price = create_estimated_price(variant, account)

      order = Repo.insert!(%Order{ account_id: account.id })
      order_quantity = 2

      changeset = OrderLineItem.changeset(%OrderLineItem{
        account_id: account.id
      }, %{
        "order_id" => order.id,
        "product_id" => variant.id,
        "order_quantity" => order_quantity
      })

      correct_translations = %{
        "zh-CN" => %{
          "name" => "苹果 大号",
          "price_name" => "原价"
        }
      }

      assert changeset.valid?
      assert changeset.changes.name == variant.name

      assert changeset.changes.is_leaf == false
      assert changeset.changes.order_quantity == order_quantity
      assert changeset.changes.charge_quantity == Price.get_estimate_average_rate(estimated_price) |> D.mult(D.new(order_quantity))

      assert changeset.changes.price_id == estimated_price.id
      assert changeset.changes.price_name == estimated_price.name
      assert changeset.changes.price_label == estimated_price.label
      assert changeset.changes.price_caption == estimated_price.caption
      assert changeset.changes.price_order_unit == estimated_price.order_unit
      assert changeset.changes.price_charge_unit == estimated_price.charge_unit
      assert changeset.changes.price_currency_code == estimated_price.currency_code
      assert changeset.changes.price_charge_amount_cents == estimated_price.charge_amount_cents
      assert changeset.changes.price_estimate_by_default == estimated_price.estimate_by_default
      assert changeset.changes.price_tax_one_percentage == estimated_price.tax_one_percentage
      assert changeset.changes.price_tax_two_percentage == estimated_price.tax_two_percentage
      assert changeset.changes.price_tax_three_percentage == estimated_price.tax_three_percentage
      assert changeset.changes.price_estimate_by_default == estimated_price.estimate_by_default
      assert changeset.changes.price_end_time == estimated_price.end_time

      assert changeset.changes.sub_total_cents == 2697
      assert changeset.changes.tax_one_cents == 135
      assert changeset.changes.tax_two_cents == 189
      assert changeset.changes.tax_three_cents == 27
      assert changeset.changes.grand_total_cents == 3048
      assert changeset.changes.authorization_total_cents == 4064
      assert changeset.changes.auto_fulfill == false

      assert changeset.changes.translations == correct_translations
    end
  end

  describe "balance!/1" do
    test "on custom order line item" do
      account = Repo.insert!(%Account{})
      order = Repo.insert!(%Order{
        account_id: account.id
      })

      item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        name: "Custom Line",
        is_leaf: true,
        parent_id: nil,
        order_quantity: 1,
        charge_quantity: 1,
        sub_total_cents: 0,
        tax_one_cents: 0,
        tax_two_cents: 0,
        tax_three_cents: 0,
        grand_total_cents: 0,
        authorization_total_cents: 0,
        auto_fulfill: false
      })

      OrderLineItem.balance!(item)
      children = Ecto.assoc(item, :children) |> Repo.all()

      assert length(children) == 0
    end

    test "on order line item with product variant" do
      %{ account: account, variant: variant } = create_product_with_variants()

      order = Repo.insert!(%Order{
        account_id: account.id
      })
      order_line_item = Repo.insert!(%OrderLineItem{
        account_id: account.id,
        order_id: order.id,
        product_id: variant.id,
        is_leaf: false,
        order_quantity: 3,
        charge_quantity: 3,
        sub_total_cents: 1000,
        tax_one_cents: 20,
        tax_two_cents: 10,
        tax_three_cents: 60,
        grand_total_cents: 1090,
        authorization_total_cents: 1090,
        auto_fulfill: false
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
      assert child.source_id == variant.source_id
      assert child.source_type == variant.source_type
    end

    # test "with OrderLineItem with Product" do
    #   account = Repo.insert!(%Account{})
    #   sku1 = Repo.insert!(%Sku{
    #     account_id: account.id,
    #     status: "active",
    #     name: "Apple",
    #     print_name: "APPLED",
    #     unit_of_measure: "EA"
    #   })
    #   sku2 = Repo.insert!(%Sku{
    #     account_id: account.id,
    #     status: "active",
    #     name: "Orange",
    #     print_name: "ORANGE",
    #     unit_of_measure: "EA"
    #   })
    #   product = Repo.insert!(%Product{
    #     status: "active",
    #     name: "Fruit Combo",
    #     item_mode: "any",
    #     account_id: account.id
    #   })
    #   product_item1 = Repo.insert!(%ProductItem{
    #     status: "active",
    #     account_id: account.id,
    #     product_id: product.id,
    #     sku_id: sku1.id,
    #     name: "Apple",
    #     source_quantity: 5
    #   })
    #   Repo.insert!(%Price{
    #     account_id: account.id,
    #     product_item_id: product_item1.id,
    #     status: "active",
    #     label: "regular",
    #     name: "Regular Price",
    #     charge_amount_cents: 1000,
    #     order_unit: "EA",
    #     charge_unit: "EA"
    #   })
    #   product_item2 = Repo.insert!(%ProductItem{
    #     status: "active",
    #     account_id: account.id,
    #     product_id: product.id,
    #     sku_id: sku2.id,
    #     name: "Orange",
    #     source_quantity: 3
    #   })
    #   Repo.insert!(%Price{
    #     account_id: account.id,
    #     product_item_id: product_item2.id,
    #     status: "active",
    #     label: "regular",
    #     name: "Regular Price",
    #     charge_amount_cents: 1000,
    #     order_unit: "EA",
    #     charge_unit: "EA"
    #   })
    #   order = Repo.insert!(%Order{
    #     account_id: account.id
    #   })
    #   order_line_item = Repo.insert!(%OrderLineItem{
    #     account_id: account.id,
    #     name: product.name,
    #     is_leaf: false,
    #     parent_id: nil,
    #     order_id: order.id,
    #     charge_quantity: 3,
    #     order_quantity: 3,
    #     product_id: product.id,
    #     sub_total_cents: 6000,
    #     tax_one_cents: 0,
    #     tax_two_cents: 0,
    #     tax_three_cents: 0,
    #     grand_total_cents: 6000
    #   })

    #   children =
    #     order_line_item
    #     |> OrderLineItem.balance!()
    #     |> OrderLineItem.balance!()
    #     |> Ecto.assoc(:children)
    #     |> Repo.all()
    #   child1 = Enum.at(children, 0)
    #   child2 = Enum.at(children, 1)

    #   assert length(children) == 2
    #   assert child1.order_quantity == 3
    #   assert child1.sub_total_cents == 3000
    #   assert child2.order_quantity == 3
    #   assert child2.sub_total_cents == 3000
    # end
  end
end
