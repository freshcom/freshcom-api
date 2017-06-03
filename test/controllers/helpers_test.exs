defmodule BlueJet.HelpersTest do
  use BlueJet.ModelCase, async: true

  alias BlueJet.Controller.Helpers

  describe "pointer_for/1" do
    test "with :fields as field" do
      assert Helpers.pointer_for(:fields) == "/data"
    end

    test "with :attributes as field" do
      assert Helpers.pointer_for(:attributes) == "/data/attributes"
    end

    test "with :relationships as field" do
      assert Helpers.pointer_for(:relationships) == "/data/relationships"
    end

    test "with :attr_name as field" do
      assert Helpers.pointer_for(:attr_name) == "/data/attributes/attrName"
    end

    test "with :one_example_id as field" do
      assert Helpers.pointer_for(:one_example_id) == "/data/relationships/oneExample"
    end
  end
end
