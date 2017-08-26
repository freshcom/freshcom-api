defmodule BlueJet.ValidationTest do
  use BlueJet.DataCase

  alias Ecto.Changeset
  alias BlueJet.Validation

  describe "validate_required_exactly_one/2" do
    test "with valid changeset" do
      data = %{}
      types = %{ name: :string, caption: :string }
      params = %{ name: "苹果" }

      original_changeset = Changeset.cast({data, types}, params, Map.keys(types))
      new_changeset = Validation.validate_required_exactly_one(original_changeset, [:name, :caption])

      assert original_changeset == new_changeset
    end

    test "with all fields provided" do
      data = %{}
      types = %{ name: :string, caption: :string }
      params = %{ name: "苹果", caption: "好苹果" }

      original_changeset = Changeset.cast({data, types}, params, Map.keys(types))
      new_changeset = Validation.validate_required_exactly_one(original_changeset, [:name, :caption])

      assert original_changeset != new_changeset
      assert new_changeset.errors[:fields]
    end

    test "with no fields provided" do
      data = %{}
      types = %{ name: :string, caption: :string }
      params = %{ }

      original_changeset = Changeset.cast({data, types}, params, Map.keys(types))
      new_changeset = Validation.validate_required_exactly_one(original_changeset, [:name, :caption])

      assert original_changeset != new_changeset
      assert new_changeset.errors[:fields]
    end
  end
end
