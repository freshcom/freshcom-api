defmodule BlueJet.CustomerTest do
  use BlueJet.ModelCase

  alias BlueJet.Customer

  @valid_attrs %{email: "test1@example.com", password: "some content", first_name: "some content", last_name: "some content", account_id: "827ae785-1502-4489-8a97-609c4840168f"}
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
