defmodule BlueJet.CustomerTest do
  use BlueJet.ModelCase, async: true

  alias BlueJet.Customer

  @valid_params %{email: "test1@example.com", password: "some content", first_name: "some content", last_name: "some content", account_id: "827ae785-1502-4489-8a97-609c4840168f"}
  @invalid_params %{}

  test "changeset with valid attributes" do
    changeset = Customer.changeset(%Customer{}, @valid_params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Customer.changeset(%Customer{}, @invalid_params)
    refute changeset.valid?
  end
end
