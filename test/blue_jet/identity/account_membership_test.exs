defmodule BlueJet.Identity.AccountMembershipTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.{Account, AccountMembership, User}

  describe "schema" do
    test "when account is deleted membership should be automatically deleted" do
      account1 = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
      account2 = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        default_account_id: account2.id
      })

      membership = Repo.insert!(%AccountMembership{
        account_id: account1.id,
        user_id: user.id,
        role: "developer"
      })

      Repo.delete!(account1)
      refute Repo.get(AccountMembership, membership.id)
    end

    test "when user is deleted membership should be automatically deleted" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        default_account_id: account.id
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
    assert AccountMembership.writable_fields() == [:role, :is_owner, :user_id]
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        %AccountMembership{}
        |> change()
        |> Map.put(:action, :insert)

      changeset = AccountMembership.validate(changeset)

      assert changeset.valid? == false
      assert changeset.errors[:user_id]
      assert changeset.errors[:role]
    end

    test "when role is not valid" do
      changeset =
        %AccountMembership{}
        |> change(%{role: "invalid"})
        |> Map.put(:action, :insert)

      changeset = AccountMembership.validate(changeset)

      assert changeset.valid? == false
      assert changeset.errors[:role]
    end

    test "when changeset is valid" do
      changeset =
        %AccountMembership{}
        |> change(%{id: Ecto.UUID.generate(), role: "invalid"})
        |> Map.put(:action, :insert)

      assert changeset.valid?
    end
  end

  describe "changeset/2" do
    test "when action is insert" do
      params = %{
        role: "developer",
        user_id: Ecto.UUID.generate()
      }

      changeset =
        %AccountMembership{}
        |> AccountMembership.changeset(:insert, params)

      assert changeset.valid?
      assert changeset.changes[:role]
      assert changeset.changes[:user_id]
    end

    test "when action is update" do
      params = %{
        role: "developer",
        user_id: Ecto.UUID.generate()
      }

      changeset =
        %AccountMembership{}
        |> AccountMembership.changeset(:update, params)

      assert changeset.valid?
      assert changeset.changes[:role]
      refute changeset.changes[:user_id]
    end
  end
end
