defmodule BlueJet.ProductTest do
  use BlueJet.ModelCase

  alias BlueJet.Product

  @valid_attrs %{author: "some content", name: "some content", number: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Product.changeset(%Product{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Product.changeset(%Product{}, @invalid_attrs)
    refute changeset.valid?
  end
end
