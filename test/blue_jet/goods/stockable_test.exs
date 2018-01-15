defmodule BlueJet.StockableTest do
  use BlueJet.DataCase
  import BlueJet.Identity.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Stockable

  # @valid_params %{
  #   account_id: Ecto.UUID.generate(),
  #   status: "active",
  #   name: "Apple",
  #   print_name: "APPLE",
  #   unit_of_measure: "EA",
  #   custom_data: %{
  #     kind: "Gala"
  #   }
  # }
  # @invalid_params %{}

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
      :avatar_id
    ]
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        change(%Stockable{ account_id: Ecto.UUID.generate() }, %{})
        |> Stockable.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :unit_of_measure]
    end
  end

  describe "changeset/4" do
    test "when given valid fields without locale" do
      account = Repo.insert!(%Account{})
      changeset = Stockable.changeset(%Stockable{ account_id: account.id }, %{
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })

      assert changeset.valid?
      assert Map.keys(changeset.changes) == [:name, :print_name, :unit_of_measure]
    end

    test "when given valid fields with locale" do
      account = Repo.insert!(%Account{})
      changeset = Stockable.changeset(%Stockable{ account_id: account.id }, %{
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      }, "en", "zh-CN")

      assert changeset.valid?
      assert Map.keys(changeset.changes) == [:translations]
    end

    test "when given invalid fields" do
      account = Repo.insert!(%Account{})
      changeset = Stockable.changeset(%Stockable{ account_id: account.id }, %{})

      refute changeset.valid?
    end
  end
end
