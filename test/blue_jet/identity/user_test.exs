defmodule BlueJet.Identity.UserTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.User
  alias BlueJet.Identity.AccountMembership

  test "writable_fields/0" do
    assert User.writable_fields == [
      :status,
      :username,
      :email,
      :phone_number,
      :name,
      :first_name,
      :last_name,
      :auth_method,
      :password,
      :current_password,
      :phone_verification_code
    ]
  end

  describe "validate/1" do
    test "when missing required fields" do
      changeset =
        change(%User{}, %{})
        |> Map.put(:action, :insert)
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:password, :username]
    end

    test "when given username less than 5 characters" do
      changeset =
        change(%User{}, %{ username: "abcd", password: "test1234" })
        |> Map.put(:action, :insert)
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:username]
    end

    test "when given global username already exist" do
      account1 = Repo.insert!(%Account{ name: Faker.Company.name() })
      account2 = Repo.insert!(%Account{ name: Faker.Company.name() })
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        password: "test1234",
        default_account_id: account1.id
      })
      Repo.insert!(%AccountMembership{
        role: "developer",
        account_id: account1.id,
        user_id: user.id
      })

      # Creating non related account user
      {:ok, _} =
        change(%User{}, %{
          username: user.username,
          password: "test1234",
          account_id: account2.id,
          default_account_id: account2.id
        })
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      # Creating related account user
      {:error, au_changeset} =
        change(%User{}, %{
          username: user.username,
          password: "test1234",
          account_id: account1.id,
          default_account_id: account1.id
        })
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      # Creating global user
      {:error, gu_changeset} =
        change(%User{}, %{
          username: user.username,
          password: "test1234",
          default_account_id: account2.id
        })
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      refute au_changeset.valid?
      refute gu_changeset.valid?
      assert Keyword.keys(au_changeset.errors) == [:username]
      assert Keyword.keys(gu_changeset.errors) == [:username]
    end

    test "when given account username already exist" do
      account1 = Repo.insert!(%Account{ name: Faker.Company.name() })
      account2 = Repo.insert!(%Account{ name: Faker.Company.name() })
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        password: "test1234",
        account_id: account1.id,
        default_account_id: account1.id
      })

      # Creating global user should pass
      {:ok, _} =
        change(%User{}, %{
          username: user.username,
          password: "test1234",
          default_account_id: account2.id
        })
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      # Creating non related account user should pass
      {:ok, _} =
        change(%User{}, %{
          username: user.username,
          password: "test1234",
          account_id: account2.id,
          default_account_id: account2.id
        })
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      # Creating related account user should error
      {:error, changeset} =
        change(%User{}, %{
          username: user.username,
          password: "test1234",
          account_id: account1.id,
          default_account_id: account1.id
        })
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:username]
    end

    test "when given invalid email" do
      changeset =
        change(%User{}, %{ username: Faker.String.base64(5), email: "invalid", password: "test1234" })
        |> Map.put(:action, :insert)
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:email]
    end

    test "when given global email already exist" do
      account1 = Repo.insert!(%Account{ name: Faker.Company.name() })
      account2 = Repo.insert!(%Account{ name: Faker.Company.name() })
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        password: "test1234",
        email: Faker.Internet.email(),
        default_account_id: account1.id
      })

      # Creating account user should pass
      {:ok, _} =
        change(%User{}, %{
          username: Faker.String.base64(5),
          password: "test1234",
          email: user.email,
          account_id: account1.id,
          default_account_id: account1.id
        })
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      # Creating global user should error
      {:error, changeset} =
        change(%User{}, %{
          username: "username2",
          password: "test1234",
          email: user.email,
          default_account_id: account2.id
        })
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:email]
    end

    test "when updating user password but did not provide current password" do
      user = %User{ username: "username" }

      changeset =
        user
        |> change(%{ password: "newpassword" })
        |> Map.put(:action, :update)
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:current_password]
    end

    test "when given password less than 8 characters" do
      changeset =
        change(%User{}, %{ username: "username", password: "abc" })
        |> Map.put(:action, :insert)
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:password]
    end

    test "when updating user password but provided wrong current password" do
      user = %User{ username: "username" }

      changeset =
        user
        |> change(%{ password: "newpassword", current_password: "wrongpassword" })
        |> Map.put(:action, :update)
        |> User.validate()

      refute changeset.valid?
      assert Keyword.keys(changeset.errors) == [:current_password]
    end

    test "when user is alreay persisted and updating" do
      user = %User{ username: Faker.String.base64(5) }

      changeset =
        user
        |> change(%{})
        |> Map.put(:action, :update)
        |> User.validate()

      assert changeset.valid?
    end
  end

  describe "changeset/1" do
    test "when username and password is given" do
      changeset = User.changeset(%User{}, :insert, %{
        username: Faker.String.base64(5),
        password: "test1234"
      })

      assert changeset.valid?
      assert changeset.changes[:encrypted_password]
    end

    test "when missing required fields" do
      changeset = User.changeset(%User{}, :insert, %{})

      refute changeset.valid?
    end
  end

  describe "get_role/2" do
    test "when the user has a role for that account" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        default_account_id: account.id
      })
      Repo.insert!(%AccountMembership{
        user_id: user.id,
        account_id: account.id,
        role: "developer"
      })

      assert User.get_role(user, account) == "developer"
    end

    test "when uesr is not part of the account" do
      user = %User{ id: Ecto.UUID.generate() }
      account = %Account{ id: Ecto.UUID.generate() }

      assert User.get_role(user, account) == nil
    end
  end

  test "refresh_password_reset_token/1" do
    account = Repo.insert!(%Account{
      name: Faker.Company.name()
    })
    user = Repo.insert!(%User{
      username: Faker.String.base64(5),
      default_account_id: account.id
    })

    user = User.refresh_password_reset_token(user)
    assert user.password_reset_token
  end
end
