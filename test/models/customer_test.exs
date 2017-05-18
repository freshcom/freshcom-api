defmodule BlueJet.CustomerTest do
  use BlueJet.ModelCase

  alias BlueJet.Customer

  @valid_attrs %{display_name: "some content", email: "some content", encrypted_password: "some content", first_name: "some content", last_name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Customer.changeset(%Customer{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Customer.changeset(%Customer{}, @invalid_attrs)
    refute changeset.valid?
  end
end
