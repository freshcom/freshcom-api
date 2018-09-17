defmodule BlueJet.Goods.UnlockableTest do
  use BlueJet.DataCase

  import BlueJet.Goods.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Unlockable

  describe "schema" do
    test "when account is deleted unlockable should be automatically deleted" do
      account = account_fixture()
      unlockable = unlockable_fixture(account)

      Repo.delete!(account)

      refute Repo.get(Unlockable, unlockable.id)
    end
  end

  test "writable_fields/0" do
    assert Unlockable.writable_fields() == [
      :status,
      :code,
      :name,
      :label,
      :print_name,
      :caption,
      :description,
      :custom_data,
      :translations,
      :avatar_id,
      :file_id
    ]
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        %Unlockable{}
        |> change(%{})
        |> Unlockable.validate()

      assert changeset.valid? == false
      assert match_keys(changeset.errors, [:name])
    end
  end

  describe "changeset/5" do
    test "when given valid fields without locale" do
      fields = %{"name" => Faker.Commerce.product_name()}
      account = %Account{id: UUID.generate()}
      unlockable = %Unlockable{account: account}

      changeset = Unlockable.changeset(unlockable, :update, fields)

      assert changeset.valid?
      assert changeset.action == :update
      assert match_keys(changeset.changes, [:name, :print_name])
    end

    test "when given valid fields with locale" do
      fields = %{"name" => Faker.Commerce.product_name()}
      account = %Account{id: UUID.generate()}
      unlockable = %Unlockable{account: account}

      changeset = Unlockable.changeset(unlockable, :update, fields, "en", "zh-CN")

      assert changeset.valid?
      assert changeset.action == :update
      assert match_keys(changeset.changes, [:translations])
    end

    test "when given invalid fields" do
      account = %Account{id: UUID.generate()}
      unlockable = %Unlockable{account: account}

      changeset = Unlockable.changeset(unlockable, :update, %{})

      assert changeset.valid? == false
    end
  end
end
