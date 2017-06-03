defmodule BlueJet.ProductItemTest do
  use BlueJet.ModelCase, async: true

  alias BlueJet.ProductItem

  @valid_params %{
    account_id: Ecto.UUID.generate(),
    status: "active",
    print_name: "APPLE",
    custom_data: %{
      kind: "Gala"
    },
    product_id: Ecto.UUID.generate(),
    sku_id: Ecto.UUID.generate()
  }
  @invalid_params %{}

  describe "schema" do
    test "defaults" do
      struct = %ProductItem{}

      assert struct.sort_index == 9999
      assert struct.quantity == 1
      assert struct.maximum_order_quantity == 9999
      assert struct.primary == false
      assert struct.custom_data == %{}
      assert struct.translations == %{}
    end
  end

  describe "changeset/1" do
    test "with struct in :built state, valid params, en locale" do
      changeset = ProductItem.changeset(%ProductItem{}, @valid_params)

      assert changeset.valid?
      assert changeset.changes.account_id
      assert changeset.changes.status
      assert changeset.changes.print_name
    end

    test "with struct in :built state, valid params, zh-CN locale" do
      changeset = ProductItem.changeset(%ProductItem{}, @valid_params, "zh-CN")

      assert changeset.valid?
      assert changeset.changes.account_id
      assert changeset.changes.status
      assert changeset.changes.translations["zh-CN"]
      refute Map.get(changeset.changes, :print_name)
      refute Map.get(changeset.changes, :custom_data)
    end

    test "with struct in :loaded state, valid params" do
      struct = Ecto.put_meta(%ProductItem{ account_id: Ecto.UUID.generate() }, state: :loaded)
      changeset = ProductItem.changeset(struct, @valid_params)

      assert changeset.valid?
      assert changeset.changes.status
      assert changeset.changes.print_name
      assert changeset.changes.custom_data
      refute Map.get(changeset.changes, :account_id)
    end

    test "with struct in :built state, invalid params" do
      changeset = ProductItem.changeset(%ProductItem{}, @invalid_params)

      refute changeset.valid?
    end
  end
end
