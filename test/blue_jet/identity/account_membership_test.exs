defmodule BlueJet.AccountMembershipTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.User
  alias BlueJet.Identity.AccountMembership

  describe "schema" do
    test "when account is deleted membership should be automatically deleted" do
      account = Repo.insert!(%Account{
        mode: "live",
        name: Faker.Company.name(),
        default_locale: "en"
      })
      user = Repo.insert!(%User{
        email: Faker.Internet.safe_email()
      })

      membership = Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: user.id,
        role: "developer"
      })

      Repo.delete!(account)
      refute Repo.get(AccountMembership, membership.id)
    end

    test "when user is deleted membership should be automatically deleted" do
      account = Repo.insert!(%Account{
        mode: "live",
        name: Faker.Company.name(),
        default_locale: "en"
      })
      user = Repo.insert!(%User{
        email: Faker.Internet.safe_email()
      })

      membership = Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: user.id,
        role: "developer"
      })

      Repo.delete!(user)
      refute Repo.get(AccountMembership, membership.id)
    end
  end

  test "writable_fields/0" do
    assert AccountMembership.writable_fields() == [:role, :user_id]
  end

  describe "validate/1" do
    test "when missing required fields should make changeset invalid" do
      changeset =
        change(%AccountMembership{}, %{})
        |> AccountMembership.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:user_id, :role]
    end

    test "when user_id does not exist insert should fail" do
      {:error, changeset} =
        change(%AccountMembership{}, %{ user_id: Ecto.UUID.generate(), role: "developer" })
        |> AccountMembership.validate()
        |> Repo.insert()

      assert Keyword.keys(changeset.errors) == [:user_id]
    end
  end

  describe "changeset/2" do
    test "when struct in :built state" do
      changeset = AccountMembership.changeset(%AccountMembership{}, %{
        role: "developer",
        user_id: Ecto.UUID.generate(),
        account_id: Ecto.UUID.generate()
      })

      assert changeset.valid?
      assert changeset.changes[:role]
      assert changeset.changes[:user_id]
      refute changeset.changes[:account_id]
    end

    test "when struct in :loaded state" do
      struct = %AccountMembership{
        user_id: Ecto.UUID.generate(),
        account_id: Ecto.UUID.generate()
      }

      changeset =
        struct
        |> Ecto.put_meta(state: :loaded)
        |> AccountMembership.changeset(%{
            role: "developer",
            user_id: Ecto.UUID.generate(),
            account_id: Ecto.UUID.generate()
           })

      assert changeset.valid?
      assert changeset.changes[:role]
      refute changeset.changes[:user_id]
      refute changeset.changes[:account_id]
    end
  end
end
