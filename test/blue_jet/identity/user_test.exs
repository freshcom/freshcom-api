defmodule BlueJet.Identity.UserTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.{Account, User, AccountMembership, PhoneVerificationCode}

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

  describe "schema" do
    test "when account is deleted account user should be automatically deleted" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })

      Repo.delete!(account)

      refute Repo.get(User, user.id)
    end
  end

  describe "validate/2" do
    test "when action is insert and missing required fields" do
      changeset =
        %User{}
        |> change(%{})
        |> Map.put(:action, :insert)
        |> User.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:password, :username, :name]
    end

    test "when action is insert and given username less than 5 characters" do
      changeset =
        %User{}
        |> change(%{ username: "abcd", password: "test1234", name: Faker.Name.name() })
        |> Map.put(:action, :insert)
        |> User.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:username]
    end

    test "when action is insert and given account username already exist" do
      account1 = Repo.insert!(%Account{ name: Faker.Company.name() })
      account2 = Repo.insert!(%Account{ name: Faker.Company.name() })
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        password: "test1234",
        name: Faker.Name.name(),
        account_id: account1.id,
        default_account_id: account1.id
      })

      params = %{
        username: user.username,
        password: "test1234",
        name: Faker.Name.name(),
        default_account_id: account2.id
      }

      # Creating standard user should pass
      {:ok, _} =
        %User{}
        |> change(params)
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      params = %{
        username: user.username,
        password: "test1234",
        name: Faker.Name.name(),
        account_id: account2.id,
        default_account_id: account2.id
      }

      # Creating non related managed user should pass
      {:ok, _} =
        %User{}
        |> change(params)
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      params = %{
        username: user.username,
        password: "test1234",
        name: Faker.Name.name(),
        account_id: account1.id,
        default_account_id: account1.id
      }

      # Creating related account user should error
      {:error, changeset} =
        %User{}
        |> change(params)
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:username]
    end

    test "when action is insert and given invalid email" do
      params = %{
        username: Faker.String.base64(5),
        name: Faker.Name.name(),
        email: "invalid",
        password: "test1234"
      }

      changeset =
        %User{}
        |> change(params)
        |> Map.put(:action, :insert)
        |> User.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:email]
    end

    test "when action is insert and given global email already exist" do
      account1 = Repo.insert!(%Account{name: Faker.Company.name()})
      account2 = Repo.insert!(%Account{name: Faker.Company.name()})
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        password: "test1234",
        email: Faker.Internet.email(),
        default_account_id: account1.id
      })

      params = %{
        username: Faker.String.base64(5),
        password: "test1234",
        email: user.email,
        name: Faker.Name.name(),
        account_id: account1.id,
        default_account_id: account1.id
      }

      # Creating account user should pass
      {:ok, _} =
        %User{}
        |> change(params)
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      params = %{
        username: "username2",
        password: "test1234",
        email: user.email,
        name: Faker.Name.name(),
        default_account_id: account2.id
      }

      # Creating global user should error
      {:error, changeset} =
        %User{}
        |> change(params)
        |> Map.put(:action, :insert)
        |> User.validate()
        |> Repo.insert()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:email]
    end

    test "when action is insert and given password less than 8 characters" do
      params = %{
        username: "username",
        password: "abc",
        name: Faker.Name.name()
      }
      changeset =
        %User{}
        |> change(params)
        |> Map.put(:action, :insert)
        |> User.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:password]
    end

    test "when action is insert, auth_method is tfa_sms and missing required fields" do
      params = %{
        auth_method: "tfa_sms",
        username: Faker.Internet.user_name(),
        password: "test1234",
        name: Faker.Name.name()
      }
      changeset =
        %User{}
        |> change(params)
        |> Map.put(:action, :insert)
        |> User.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:phone_verification_code, :phone_number]
    end

    test "when action is insert, auth_method is tfa_sms and phone_verification_code is invalid" do
      params = %{
        auth_method: "tfa_sms",
        username: Faker.Internet.user_name(),
        password: "test1234",
        name: Faker.Name.name(),
        phone_number: "+11234567890",
        phone_verification_code: "123456"
      }

      changeset =
        %User{}
        |> change(params)
        |> Map.put(:action, :insert)
        |> User.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:phone_verification_code]
    end

    test "when action is insert, auth_method is tfa_sms and all changes are valid" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
      pvc = Repo.insert!(%PhoneVerificationCode{
        account_id: account.id,
        phone_number: "+11234567890",
        value: "123456",
        expires_at: Timex.shift(Timex.now(), minutes: 5)
      })

      params = %{
        auth_method: "tfa_sms",
        username: Faker.Internet.user_name(),
        password: "test1234",
        name: Faker.Name.name(),
        phone_number: pvc.phone_number,
        phone_verification_code: pvc.value
      }

      changeset =
        %User{}
        |> change(params)
        |> Map.put(:action, :insert)
        |> User.validate()

      assert changeset.valid? == true
    end

    test "when action is update but missing required fields" do
      user = %User{username: "username", name: Faker.Name.name()}

      changeset =
        user
        |> change(%{password: "newpassword"})
        |> Map.put(:action, :update)
        |> User.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:current_password]
    end

    test "when action is update and password is changed but provided wrong current password" do
      user = %User{username: "username", name: Faker.Name.name()}

      changeset =
        user
        |> change(%{password: "newpassword", current_password: "wrongpassword"})
        |> Map.put(:action, :update)
        |> User.validate()

      assert changeset.valid? == false
      assert Keyword.keys(changeset.errors) == [:current_password]
    end

    test "when action is update" do
      user = %User{username: Faker.String.base64(5), name: Faker.Name.name()}

      changeset =
        user
        |> change(%{})
        |> Map.put(:action, :update)
        |> User.validate()

      assert changeset.valid?
    end
  end

  describe "changeset/3" do
    test "when action is insert" do
      account = Repo.insert!(%Account{default_auth_method: "tfa_sms"})
      params = %{
        username: " Tes t ",
        email: " te s t@example.com  ",
        password: "test1234",
        phone_verification_code: "123456",
        first_name: "Roy",
        last_name: "Bao"
      }

      changeset =
        %User{account_id: account.id, account: account}
        |> User.changeset(:insert, params)

      assert changeset.changes[:encrypted_password]
      assert changeset.changes[:username] == "test"
      assert changeset.changes[:email] == "test@example.com"
      assert changeset.changes[:auth_method] == "tfa_sms"
      assert changeset.changes[:tfa_code] == "123456"
      assert changeset.changes[:name] == "Roy Bao"
    end

    test "when action is update" do
      params = %{
        username: " Tes t ",
        email: " te s t@example.com  ",
        password: "test1234",
        phone_verification_code: "123456",
        first_name: "Roy",
        last_name: "Bao"
      }

      changeset =
        %User{}
        |> User.changeset(:update, params)

      assert changeset.changes[:encrypted_password]
      assert changeset.changes[:username] == "test"
      assert changeset.changes[:email] == "test@example.com"
      assert changeset.changes[:name] == "Roy Bao"
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

      assert User.get_role(user, account.id) == "developer"
    end

    test "when uesr is not part of the account" do
      user = %User{id: Ecto.UUID.generate()}
      account = %Account{id: Ecto.UUID.generate()}

      assert User.get_role(user, account.id) == nil
    end
  end

  describe "get_tfa_code/1" do
    test "when tfa code expired" do
      user = %User{tfa_code: "123456", tfa_code_expires_at: Timex.now()}

      assert User.get_tfa_code(user) == nil
    end

    test "when tfa code is valid" do
      user = %User{tfa_code: "123456", tfa_code_expires_at: Timex.shift(Timex.now(), minutes: 1)}

      assert User.get_tfa_code(user) == "123456"
    end
  end
end
