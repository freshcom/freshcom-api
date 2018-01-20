defmodule BlueJet.Goods.DepositableTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Goods.Depositable

  describe "schema" do
    test "when account is deleted depositable should be automatically deleted" do
      account = Repo.insert!(%Account{})
      depositable = Repo.insert!(%Depositable{
        account_id: account.id,
        name: Faker.String.base64(5),
        amount: 500,
        target_type: "PointAccount"
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
      :target_type,
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
        change(%Depositable{ account_id: Ecto.UUID.generate() }, %{})
        |> Depositable.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:name, :amount, :target_type]
    end
  end

  describe "changeset/4" do
    test "when given valid fields without locale" do
      account = Repo.insert!(%Account{})
      changeset = Depositable.changeset(%Depositable{ account_id: account.id }, %{
        name: Faker.String.base64(5),
        amount: 500,
        target_type: "PointAccount"
      })

      assert changeset.valid?
      assert Map.keys(changeset.changes) == [:amount, :name, :print_name, :target_type]
    end

    test "when given valid fields with locale" do
      account = Repo.insert!(%Account{})
      changeset = Depositable.changeset(%Depositable{ account_id: account.id }, %{
        name: Faker.String.base64(5),
        amount: 500,
        target_type: "PointAccount"
      }, "en", "zh-CN")

      assert changeset.valid?
      assert Map.keys(changeset.changes) == [:amount, :target_type, :translations]
    end

    test "when given invalid fields" do
      account = Repo.insert!(%Account{})
      changeset = Depositable.changeset(%Depositable{ account_id: account.id }, %{})

      refute changeset.valid?
    end
  end
end
