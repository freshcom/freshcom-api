defmodule BlueJet.ProductItemTest do
  use BlueJet.DataCase

  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Identity.Account
  alias BlueJet.Storefront.Product
  alias BlueJet.Inventory.Sku

  @invalid_params %{}

  setup do
    account1 = Repo.insert!(%Account{})

    product1 = Repo.insert!(%Product{
      account_id: account1.id,
      status: "active",
      name: "Apple"
    })

    sku1 = Repo.insert!(%Sku{
      account_id: account1.id,
      status: "active",
      name: "Orange",
      print_name: "ORANGE",
      unit_of_measure: "EA"
    })

    valid_params = %{
      account_id: account1.id,
      status: "active",
      custom_data: %{
        kind: "Gala"
      },
      product_id: product1.id,
      sku_id: sku1.id
    }

    %{ account1_id: account1.id, sku1_id: sku1.id, product1_id: product1.id, valid_params: valid_params }
  end

  describe "schema" do
    test "defaults" do
      struct = %ProductItem{}

      assert struct.sort_index == 9999
      assert struct.source_quantity == 1
      assert struct.maximum_public_order_quantity == 9999
      assert struct.primary == false
      assert struct.custom_data == %{}
      assert struct.translations == %{}
    end
  end

  describe "changeset/1" do
    test "with struct in :built state, valid params, en locale", %{ valid_params: valid_params } do
      changeset = ProductItem.changeset(%ProductItem{}, valid_params)

      assert changeset.valid?
      assert changeset.changes.account_id
      assert changeset.changes.status
    end

    test "with struct in :built state, valid params, zh-CN locale", %{ valid_params: valid_params } do
      changeset = ProductItem.changeset(%ProductItem{}, valid_params, "zh-CN")

      assert changeset.valid?
      assert changeset.changes.account_id
      assert changeset.changes.status
      assert changeset.changes.translations["zh-CN"]
      refute Map.get(changeset.changes, :custom_data)
    end

    test "with struct in :loaded state, valid params", %{ valid_params: valid_params, account1_id: account1_id, product1_id: product1_id } do
      struct = Ecto.put_meta(%ProductItem{ account_id: account1_id, product_id: product1_id, name: "Apple" }, state: :loaded)
      changeset = ProductItem.changeset(struct, valid_params)

      assert changeset.valid?
      assert changeset.changes.status
      assert changeset.changes.custom_data
      refute Map.get(changeset.changes, :account_id)
    end

    test "with struct in :built state, invalid params" do
      changeset = ProductItem.changeset(%ProductItem{}, @invalid_params)

      refute changeset.valid?
      assert changeset.errors[:relationships]
      assert changeset.errors[:status]
      assert changeset.errors[:product_id]
    end
  end
end
