defmodule BlueJet.Goods.StockableTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Stockable
  alias BlueJet.Goods.IdentityServiceMock

  describe "schema" do
    test "when account is deleted stockable should be automatically deleted" do
      account = Repo.insert!(%Account{})
      stockable = Repo.insert!(%Stockable{
        account_id: account.id,
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })
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
        change(%Stockable{ account_id: Ecto.UUID.generate() }, %{})
        |> Stockable.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :unit_of_measure]
    end
  end

  describe "changeset/4" do
    test "when given valid fields without locale" do
      account = %Account{
        id: Ecto.UUID.generate()
      }
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      changeset = Stockable.changeset(%Stockable{ account_id: account.id }, %{
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      })

      assert changeset.valid?
      assert Map.keys(changeset.changes) == [:name, :print_name, :unit_of_measure]
    end

    test "when given valid fields with locale" do
      account = %Account{
        id: Ecto.UUID.generate()
      }
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      changeset = Stockable.changeset(%Stockable{ account_id: account.id }, %{
        name: Faker.String.base64(5),
        unit_of_measure: Faker.String.base64(2)
      }, "en", "zh-CN")

      assert changeset.valid?
      assert Map.keys(changeset.changes) == [:translations]
    end

    test "when given invalid fields" do
      account = %Account{
        id: Ecto.UUID.generate()
      }
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      changeset = Stockable.changeset(%Stockable{ account_id: account.id }, %{})

      refute changeset.valid?
    end
  end
end
