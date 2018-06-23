defmodule BlueJet.Goods.DepositableTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Depositable
  alias BlueJet.Goods.IdentityServiceMock

  describe "schema" do
    test "when account is deleted depositable should be automatically deleted" do
      account = Repo.insert!(%Account{})
      depositable = Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.String.base64(5),
        amount: 500,
        gateway: "freshcom"
      })
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

  describe "changeset/4" do
    test "when given valid fields without locale" do
      account = %Account{
        id: Ecto.UUID.generate()
      }
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      changeset = Depositable.changeset(%Depositable{ account_id: account.id }, :update, %{
        name: Faker.String.base64(5),
        amount: 500,
        gateway: "freshcom"
      })

      assert changeset.valid?
      assert Map.keys(changeset.changes) == [:amount, :gateway, :name, :print_name]
    end

    test "when given valid fields with locale" do
      account = %Account{
        id: Ecto.UUID.generate()
      }
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      changeset = Depositable.changeset(%Depositable{ account_id: account.id }, :update, %{
        name: Faker.String.base64(5),
        amount: 500,
        gateway: "freshcom"
      }, "en", "zh-CN")

      assert changeset.valid?
      assert Map.keys(changeset.changes) == [:amount, :gateway, :translations]
    end

    test "when given invalid fields" do
      account = %Account{
        id: Ecto.UUID.generate()
      }
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      changeset = Depositable.changeset(%Depositable{ account_id: account.id }, :update, %{})

      refute changeset.valid?
    end
  end
end
