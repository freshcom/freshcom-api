defmodule BlueJet.Goods.DepositableTest do
  use BlueJet.DataCase

  import BlueJet.Goods.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Depositable

  describe "schema" do
    test "when account is deleted depositable should be automatically deleted" do
      account = account_fixture()
      depositable = depositable_fixture(account)

      Repo.delete!(account)

      refute Repo.get(Depositable, depositable.id)
    end
  end

  test "writable_fields/0" do
    assert Depositable.writable_fields() == [
      :status,
      :code,
      :name,
      :label,
      :print_name,
      :amount,
      :gateway,
      :caption,
      :description,
      :custom_data,
      :translations,
      :avatar_id
    ]
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        %Depositable{}
        |> change(%{})
        |> Depositable.validate()

      assert changeset.valid? == false
      assert match_keys(changeset.errors, [:name, :gateway, :amount])
    end
  end

  describe "changeset/5" do
    test "when given valid fields without locale" do
      fields = %{
        "name" => Faker.Commerce.product_name(),
        "gateway" => "freshcom",
        "amount" => System.unique_integer([:positive])
      }
      account = %Account{id: UUID.generate()}
      depositable = %Depositable{account: account}
      changeset = Depositable.changeset(depositable, :update, fields)

      assert changeset.valid?
      assert changeset.action == :update
      assert match_keys(changeset.changes, [:name, :print_name, :gateway, :amount])
    end

    test "when given valid fields with locale" do
      fields = %{
        "name" => Faker.Commerce.product_name(),
        "gateway" => "freshcom",
        "amount" => System.unique_integer([:positive])
      }
      account = %Account{id: UUID.generate(), default_locale: "zh-CN"}
      depositable = %Depositable{account: account}
      changeset = Depositable.changeset(depositable, :update, fields, "en")

      assert changeset.valid?
      assert changeset.action == :update
      assert match_keys(changeset.changes, [:translations, :gateway, :amount])
    end

    test "when given invalid fields" do
      account = %Account{id: UUID.generate()}
      depositable = %Depositable{account: account}

      changeset = Depositable.changeset(depositable, :update, %{})

      assert changeset.valid? == false
    end
  end
end
