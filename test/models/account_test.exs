defmodule BlueJet.AccountTest do
  use BlueJet.ModelCase

  alias BlueJet.Account

  @valid_attrs %{ name: Faker.Company.name() }
  @invalid_attrs %{}

  describe "changeset/1" do
    test "with valid attributes" do
      changeset = Account.changeset(%Account{}, @valid_attrs)
      assert changeset.valid?
    end

    test "with invalid attributes" do
      changeset = Account.changeset(%Account{}, @invalid_attrs)
      refute changeset.valid?
    end
  end

end
