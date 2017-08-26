defmodule BlueJet.AccountTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account

  @valid_params %{ name: Faker.Company.name() }
  @invalid_params %{}

  describe "changeset/1" do
    test "with valid attributes" do
      changeset = Account.changeset(%Account{}, @valid_params)
      assert changeset.valid?
    end

    test "with invalid attributes" do
      changeset = Account.changeset(%Account{}, @invalid_params)
      refute changeset.valid?
    end
  end

end
