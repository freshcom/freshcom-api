defmodule BlueJet.ProductTest do
  use BlueJet.DataCase, async: true

  alias BlueJet.Storefront.Product

  @valid_params %{
    account_id: Ecto.UUID.generate(),
    status: "active",
    name: "Apple",
    item_mode: "all",
    custom_data: %{
      kind: "Gala"
    }
  }
  @invalid_params %{}

  describe "schema" do
    test "defaults" do
      struct = %Product{}

      assert struct.item_mode == "any"
      assert struct.custom_data == %{}
      assert struct.translations == %{}
    end
  end

  describe "changeset/1" do
    test "with struct in :built state, valid params, en locale" do
      changeset = Product.changeset(%Product{}, @valid_params)

      assert changeset.valid?
      assert changeset.changes.account_id
      assert changeset.changes.status
      assert changeset.changes.name
      assert changeset.changes.item_mode
    end

    test "with struct in :built state, valid params, zh-CN locale" do
      changeset = Product.changeset(%Product{}, @valid_params, "zh-CN")

      assert changeset.valid?
      assert changeset.changes.account_id
      assert changeset.changes.status
      assert changeset.changes.item_mode
      assert changeset.changes.translations["zh-CN"]
      refute Map.get(changeset.changes, :name)
      refute Map.get(changeset.changes, :custom_data)
    end

    test "with struct in :loaded state, valid params" do
      struct = Ecto.put_meta(%Product{ account_id: Ecto.UUID.generate() }, state: :loaded)
      changeset = Product.changeset(struct, @valid_params)

      assert changeset.valid?
      assert changeset.changes.status
      assert changeset.changes.name
      assert changeset.changes.item_mode
      assert changeset.changes.custom_data
      refute Map.get(changeset.changes, :account_id)
    end

    test "with struct in :built state, invalid params" do
      changeset = Product.changeset(%Product{}, @invalid_params)

      refute changeset.valid?
    end
  end
end
