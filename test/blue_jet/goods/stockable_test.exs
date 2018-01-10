defmodule BlueJet.StockableTest do
  use BlueJet.DataCase
  import BlueJet.Identity.TestHelper

  alias BlueJet.Goods.Stockable

  @valid_params %{
    account_id: Ecto.UUID.generate(),
    status: "active",
    name: "Apple",
    print_name: "APPLE",
    unit_of_measure: "EA",
    custom_data: %{
      kind: "Gala"
    }
  }
  @invalid_params %{}

  describe "changeset/2" do
    test "with struct in :built state, valid params, en locale" do
      changeset = Stockable.changeset(%Stockable{}, @valid_params)

      assert changeset.valid?
      assert changeset.changes.account_id
      assert changeset.changes.status
      assert changeset.changes.name
      assert changeset.changes.print_name
      assert changeset.changes.unit_of_measure
      assert changeset.changes.custom_data
    end

    test "with struct in :loaded state, valid params" do
      %{ account: account } = create_global_identity("guest")
      struct = Ecto.put_meta(%Stockable{ account_id: account.id }, state: :loaded)
      changeset = Stockable.changeset(struct, @valid_params)

      assert changeset.valid?
      assert changeset.changes.status
      assert changeset.changes.name
      assert changeset.changes.print_name
      assert changeset.changes.unit_of_measure
      assert changeset.changes.custom_data
      refute Map.get(changeset.changes, :account_id)
    end

    test "with struct in :built state, invalid params" do
      changeset = Stockable.changeset(%Stockable{}, @invalid_params)

      refute changeset.valid?
    end
  end

  describe "changeset/4" do
    test "with struct in :built state, valid params, zh-CN locale" do
      changeset = Stockable.changeset(%Stockable{}, @valid_params, "zh-CN", "en")

      assert changeset.valid?
      assert changeset.changes.account_id
      assert changeset.changes.status
      assert changeset.changes.translations["zh-CN"]
      refute Map.get(changeset.changes, :name)
      refute Map.get(changeset.changes, :print_name)
      refute Map.get(changeset.changes, :custom_data)
    end
  end
end
