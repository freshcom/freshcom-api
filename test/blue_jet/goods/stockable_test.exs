defmodule BlueJet.Goods.StockableTest do
  use BlueJet.DataCase

  import BlueJet.Goods.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Stockable

  describe "schema" do
    test "when account is deleted stockable should be automatically deleted" do
      account = account_fixture()
      stockable = stockable_fixture(account)

      Repo.delete!(account)

      refute Repo.get(Stockable, stockable.id)
    end
  end

  test "writable_fields/0" do
    assert Stockable.writable_fields() == [
      :status,
      :code,
      :name,
      :label,
      :print_name,
      :unit_of_measure,
      :variable_weight,
      :storage_type,
      :storage_size,
      :stackable,
      :specification,
      :storage_description,
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
        %Stockable{}
        |> change(%{})
        |> Stockable.validate()

      assert changeset.valid? == false
      assert match_keys(changeset.errors, [:name, :unit_of_measure])
    end
  end

  describe "changeset/5" do
    test "when given valid fields without locale" do
      fields = %{
        "name" => Faker.Commerce.product_name(),
        "unit_of_measure" => Faker.String.base64(2)
      }
      account = %Account{id: UUID.generate()}
      stockable = %Stockable{account: account}
      changeset = Stockable.changeset(stockable, :update, fields)

      assert changeset.valid?
      assert changeset.action == :update
      assert match_keys(changeset.changes, [:name, :print_name, :unit_of_measure])
    end

    test "when given valid fields with locale" do
      fields = %{
        "name" => Faker.Commerce.product_name(),
        "unit_of_measure" => Faker.String.base64(2)
      }
      account = %Account{id: UUID.generate()}
      stockable = %Stockable{account: account}
      changeset = Stockable.changeset(stockable, :update, fields, "en", "zh-CN")

      assert changeset.valid?
      assert changeset.action == :update
      assert match_keys(changeset.changes, [:translations])
    end

    test "when given invalid fields" do
      account = %Account{id: UUID.generate()}
      stockable = %Stockable{account: account}

      changeset = Stockable.changeset(stockable, :update, %{})

      assert changeset.valid? == false
    end
  end
end
