defmodule BlueJet.CustomDataTest do
  use BlueJet.DataCase, async: true

  alias Ecto.Changeset
  alias BlueJet.CustomData

  describe "put_change/3" do
    test "when there is no custom data" do
      data = %{}
      types = %{ name: :string, caption: :string }

      params = %{ name: "苹果", caption: "好苹果" }
      original_changeset = Changeset.cast({data, types}, params, Map.keys(types))
      new_changeset = CustomData.put_change(original_changeset, params, [:name, :caption])

      assert new_changeset == original_changeset
    end

    test "when there is custom data" do
      data = %{}
      types = %{ name: :string, caption: :string }

      params = %{ name: "苹果", caption: "好苹果", custom1: "Custom Data" }
      original_changeset = Changeset.cast({data, types}, params, Map.keys(types))
      new_changeset = CustomData.put_change(original_changeset, params, [:name, :caption])

      assert new_changeset != original_changeset
      assert new_changeset.changes.custom_data
      assert new_changeset.changes.custom_data[:custom1]
      refute Map.get(new_changeset.changes, :custom1)
    end
  end

  describe "deserialize/1" do
    test "when there is custom data" do
      original_struct = %{ name: "Apple", custom_data: %{ "custom1" => "Custom Data" } }
      new_struct = CustomData.deserialize(original_struct)

      assert new_struct != original_struct
      assert new_struct.custom1 == "Custom Data"
    end
  end
end
