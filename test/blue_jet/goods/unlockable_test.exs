defmodule BlueJet.Goods.UnlockableTest do
  use BlueJet.DataCase

  import Mox

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Unlockable
  alias BlueJet.Goods.IdentityServiceMock

  describe "schema" do
    test "when account is deleted unlockable should be automatically deleted" do
      account = Repo.insert!(%Account{})
      unlockable = Repo.insert!(%Unlockable{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
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

  describe "changeset/4" do
    test "when given valid fields without locale" do
      account = %Account{
        id: Ecto.UUID.generate()
      }
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      changeset = Unlockable.changeset(%Unlockable{ account_id: account.id }, :update, %{
        name: Faker.String.base64(5)
      })

      assert changeset.valid?
      assert Map.keys(changeset.changes) == [:name, :print_name]
    end

    test "when given valid fields with locale" do
      account = %Account{
        id: Ecto.UUID.generate()
      }
      IdentityServiceMock
      |> expect(:get_account, fn(_) -> account end)

      changeset = Unlockable.changeset(%Unlockable{ account_id: account.id }, :update, %{
        name: Faker.String.base64(5)
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

      changeset = Unlockable.changeset(%Unlockable{ account_id: account.id }, :update, %{})

      refute changeset.valid?
    end
  end
end
