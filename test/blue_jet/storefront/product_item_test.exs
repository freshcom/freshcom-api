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

    sku2 = Repo.insert!(%Sku{
      account_id: account1.id,
      status: "active",
      name: "Orange1",
      print_name: "ORANGE1",
      unit_of_measure: "EA"
    })

    valid_params = %{
      account_id: account1.id,
      status: "active",
      name: "Apple",
      custom_data: %{
        kind: "Gala"
      },
      product_id: product1.id,
      sku_id: sku1.id
    }

    %{ account1_id: account1.id, sku1_id: sku1.id, sku2_id: sku2.id, product1_id: product1.id, valid_params: valid_params }
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

  # describe "changeset/1" do
  #   test "with struct in :built state, valid params, en locale", %{ valid_params: valid_params } do
  #     changeset = ProductItem.changeset(%ProductItem{}, valid_params)

  #     assert changeset.valid?
  #     assert changeset.changes.account_id
  #     assert changeset.changes.status
  #   end

  #   test "with struct in :built state, valid params, zh-CN locale", %{ valid_params: valid_params } do
  #     changeset = ProductItem.changeset(%ProductItem{}, valid_params, "zh-CN")

  #     assert changeset.valid?
  #     assert changeset.changes.account_id
  #     assert changeset.changes.status
  #     assert changeset.changes.translations["zh-CN"]
  #     refute Map.get(changeset.changes, :custom_data)
  #   end

  #   test "with struct in :loaded state, valid params", %{ valid_params: valid_params, account1_id: account1_id, product1_id: product1_id } do
  #     struct = Ecto.put_meta(%ProductItem{ account_id: account1_id, product_id: product1_id, name: "Apple" }, state: :loaded)
  #     changeset = ProductItem.changeset(struct, valid_params)

  #     assert changeset.valid?
  #     assert changeset.changes.status
  #     assert changeset.changes.custom_data
  #     refute Map.get(changeset.changes, :account_id)
  #   end

  #   test "with struct in :built state, invalid params" do
  #     changeset = ProductItem.changeset(%ProductItem{}, @invalid_params)

  #     refute changeset.valid?
  #     assert changeset.errors[:relationships]
  #     assert changeset.errors[:status]
  #     assert changeset.errors[:product_id]
  #   end
  # end

  describe "validate_status/1" do
    test "with the only Active ProductItem of an Active Product and changing status from Active to Disabled", %{ account1_id: account1_id, sku1_id: sku1_id } do
      active_product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: active_product.id,
        status: "active",
        name: "Apple"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "disabled" })
        |> ProductItem.validate_status()

      refute changeset.valid?
      assert changeset.errors[:status]
    end

    test "with the only Active ProductItem of an Active Product and changing status from Active to Internal", %{ account1_id: account1_id, sku1_id: sku1_id } do
      active_product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: active_product.id,
        status: "active",
        name: "Apple"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "internal" })
        |> ProductItem.validate_status()

      refute changeset.valid?
      assert changeset.errors[:status]
    end

    test "with one of many Active ProductItem of an Active Product and changing status from Active to Disabled", %{ account1_id: account1_id, sku1_id: sku1_id, sku2_id: sku2_id } do
      active_product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: active_product.id,
        status: "active",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku2_id,
        product_id: active_product.id,
        status: "active",
        name: "Apple1"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "disabled" })
        |> ProductItem.validate_status()

      assert changeset.valid?
    end

    test "with one of many Active ProductItem of an Active Product and changing status from Active to Internal", %{ account1_id: account1_id, sku1_id: sku1_id, sku2_id: sku2_id } do
      active_product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: active_product.id,
        status: "active",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku2_id,
        product_id: active_product.id,
        status: "active",
        name: "Apple1"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "internal" })
        |> ProductItem.validate_status()

      assert changeset.valid?
    end

    test "with the only Active ProductItem of an Internal Product and changing status from Active to Disabled", %{ account1_id: account1_id, sku1_id: sku1_id } do
      internal_product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "internal",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: internal_product.id,
        status: "active",
        name: "Apple"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "disabled" })
        |> ProductItem.validate_status()

      refute changeset.valid?
      assert changeset.errors[:status]
    end

    test "with the only Active ProductItem of an Internal Product and changing status from Active to Internal", %{ account1_id: account1_id, sku1_id: sku1_id } do
      internal_product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "internal",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: internal_product.id,
        status: "active",
        name: "Apple"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "internal" })
        |> ProductItem.validate_status()

      assert changeset.valid?
    end

    test "with one of many Active ProductItem of an Internal Product and changing status from Active to Disabled", %{ account1_id: account1_id, sku1_id: sku1_id, sku2_id: sku2_id } do
      internal_product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: internal_product.id,
        status: "active",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku2_id,
        product_id: internal_product.id,
        status: "active",
        name: "Apple1"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "disabled" })
        |> ProductItem.validate_status()

      assert changeset.valid?
    end

    test "with one of many Active ProductItem of an Internal Product and changing status from Active to Internal", %{ account1_id: account1_id, sku1_id: sku1_id, sku2_id: sku2_id } do
      internal_product = Repo.insert!(%Product{
        account_id: account1_id,
        status: "active",
        name: "Apple"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: internal_product.id,
        status: "active",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku2_id,
        product_id: internal_product.id,
        status: "active",
        name: "Apple1"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "internal" })
        |> ProductItem.validate_status()

      assert changeset.valid?
    end

    test "with one of many Active ProductItem of an Active Combo and changing status from Active to Disabled", %{ account1_id: account1_id, sku1_id: sku1_id, sku2_id: sku2_id } do
      active_combo = Repo.insert!(%Product{
        account_id: account1_id,
        item_mode: "all",
        status: "active",
        name: "Apple"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: active_combo.id,
        status: "active",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku2_id,
        product_id: active_combo.id,
        status: "active",
        name: "Apple1"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "disabled" })
        |> ProductItem.validate_status()

      refute changeset.valid?
    end

    test "with one of many Active ProductItem of an Active Combo and changing status from Active to Internal", %{ account1_id: account1_id, sku1_id: sku1_id, sku2_id: sku2_id } do
      active_combo = Repo.insert!(%Product{
        account_id: account1_id,
        item_mode: "all",
        status: "active",
        name: "Apple"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: active_combo.id,
        status: "active",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku2_id,
        product_id: active_combo.id,
        status: "active",
        name: "Apple1"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "internal" })
        |> ProductItem.validate_status()

      refute changeset.valid?
    end

    test "with one of many Active ProductItem of an Internal Combo and changing status from Active to Disabled", %{ account1_id: account1_id, sku1_id: sku1_id, sku2_id: sku2_id } do
      internal_combo = Repo.insert!(%Product{
        account_id: account1_id,
        item_mode: "all",
        status: "internal",
        name: "Apple"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: internal_combo.id,
        status: "active",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku2_id,
        product_id: internal_combo.id,
        status: "active",
        name: "Apple1"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "disabled" })
        |> ProductItem.validate_status()

      refute changeset.valid?
    end

    test "with one of many Active ProductItem of an Internal Combo and changing status from Active to Internal", %{ account1_id: account1_id, sku1_id: sku1_id, sku2_id: sku2_id } do
      internal_comboe = Repo.insert!(%Product{
        account_id: account1_id,
        item_mode: "all",
        status: "internal",
        name: "Apple"
      })
      Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku1_id,
        product_id: internal_comboe.id,
        status: "active",
        name: "Apple"
      })
      product_item = Repo.insert!(%ProductItem{
        account_id: account1_id,
        sku_id: sku2_id,
        product_id: internal_comboe.id,
        status: "active",
        name: "Apple1"
      })

      changeset =
        product_item
        |> Ecto.Changeset.change(%{ status: "internal" })
        |> ProductItem.validate_status()

      assert changeset.valid?
    end
  end
end
