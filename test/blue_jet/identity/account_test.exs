defmodule BlueJet.AccountTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account

  @valid_params %{
    name: Faker.Company.name(),
    default_locale: "en"
  }
  @invalid_params %{}

  describe "changeset/3" do
    test "with valid attributes" do
      changeset = Account.changeset(%Account{}, @valid_params, "en")
      assert changeset.valid?
    end

    test "with invalid attributes" do
      changeset = Account.changeset(%Account{}, @invalid_params, "en")
      refute changeset.valid?
    end
  end

end
