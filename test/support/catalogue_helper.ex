defmodule BlueJet.Catalogue.TestHelper do
  import BlueJet.Goods.TestHelper

  alias BlueJet.Catalogue.Service

  def product_fixture(account, fields \\ %{}, _ \\ []) do
    stockable = stockable_fixture(account)
    status = fields[:status] || "draft"

    default_fields = %{
      name: Faker.Commerce.product_name(),
      goods_id: stockable.id,
      goods_type: "Stockable",
      translations: %{
        "zh-CN" => %{
          "name" => Enum.random(["苹果", "橙子", "芒果", "桃子", "西瓜"])
        }
      }
    }
    fields = Map.merge(default_fields, Map.drop(fields, [:status]))

    {:ok, product} = Service.create_product(fields, %{account: account})

    if status == "active" do
      price_fixture(account, product)
      {:ok, product} = Service.update_product(%{id: product.id}, %{status: "active"}, %{account: account})

      product
    else
      product
    end
  end

  def price_fixture(account, product, fields \\ %{}) do
    default_fields = %{
      name: Faker.String.base64(5),
      status: "active",
      charge_amount_cents: System.unique_integer([:positive]),
      charge_unit: Faker.String.base64(2),
      minimum_order_quantity: System.unique_integer([:positive]),
      product_id: product.id
    }
    fields = Map.merge(default_fields, fields)

    {:ok, price} = Service.create_price(fields, %{account: account})

    price
  end

  def product_collection_fixture(account, fields \\ %{}) do
    default_fields = %{
      name: Faker.String.base64(5),
      status: "active"
    }
    fields = Map.merge(default_fields, fields)

    {:ok, collection} = Service.create_product_collection(fields, %{account: account})

    collection
  end

  def product_collection_membership_fixture(account, product, collection, fields \\ %{}) do
    default_fields = %{
      product_id: product.id,
      collection_id: collection.id
    }
    fields = Map.merge(default_fields, fields)

    {:ok, membership} = Service.create_product_collection_membership(fields, %{account: account})

    membership
  end
end
