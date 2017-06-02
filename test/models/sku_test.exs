defmodule BlueJet.SkuTest do
  use BlueJet.ModelCase, async: true

  alias BlueJet.Sku

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

  describe "changeset/1" do
    test "with struct in :built state, valid params, en locale" do
      changeset = Sku.changeset(%Sku{}, @valid_params)

      assert changeset.valid?
      assert changeset.changes.account_id
      assert changeset.changes.status
      assert changeset.changes.name
      assert changeset.changes.print_name
      assert changeset.changes.unit_of_measure
      assert changeset.changes.custom_data
    end

    test "with struct in :built state, valid params, zh-CN locale" do
      changeset = Sku.changeset(%Sku{}, @valid_params, "zh-CN")

      assert changeset.valid?
      assert changeset.changes.account_id
      assert changeset.changes.status
      assert changeset.changes.unit_of_measure
      assert changeset.changes.translations["zh-CN"]
      refute Map.get(changeset.changes, :name)
      refute Map.get(changeset.changes, :print_name)
      refute Map.get(changeset.changes, :custom_data)
    end

    test "with struct in :loaded state, valid params" do
      struct = Ecto.put_meta(%Sku{ account_id: Ecto.UUID.generate() }, state: :loaded)
      changeset = Sku.changeset(struct, @valid_params)

      assert changeset.valid?
      assert changeset.changes.status
      assert changeset.changes.name
      assert changeset.changes.print_name
      assert changeset.changes.unit_of_measure
      assert changeset.changes.custom_data
      refute Map.get(changeset.changes, :account_id)
    end

    test "with struct in :built state, invalid params" do
      changeset = Sku.changeset(%Sku{}, @invalid_params)

      refute changeset.valid?
    end
  end
end
