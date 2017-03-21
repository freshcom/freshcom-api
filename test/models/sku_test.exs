defmodule BlueJet.SkuTest do
  use BlueJet.ModelCase

  alias BlueJet.Sku

  @valid_attrs %{name: "some content", number: "some content", print_name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Sku.changeset(%Sku{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Sku.changeset(%Sku{}, @invalid_attrs)
    refute changeset.valid?
  end
end
