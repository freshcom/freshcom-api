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

  # describe "validate/1" do
  #   test "when action is insert and missing required fields" do
  #     changeset =
  #       change(%User{}, %{})
  #       |> Map.put(:action, :insert)
  #       |> User.validate()

  #     assert changeset.valid? == false
  #     assert Keyword.keys(changeset.errors) == [:password, :username]
  #   end

  #   test "when action is insert and  given username less than 5 characters" do
  #     changeset =
  #       change(%User{}, %{ username: "abcd", password: "test1234" })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()

  #     assert changeset.valid? == false
  #     assert Keyword.keys(changeset.errors) == [:username]
  #   end

  #   test "when action is insert and given global username already exist" do
  #     account1 = Repo.insert!(%Account{ name: Faker.Company.name() })
  #     account2 = Repo.insert!(%Account{ name: Faker.Company.name() })
  #     user = Repo.insert!(%User{
  #       username: Faker.String.base64(5),
  #       password: "test1234",
  #       default_account_id: account1.id
  #     })
  #     Repo.insert!(%AccountMembership{
  #       role: "developer",
  #       account_id: account1.id,
  #       user_id: user.id
  #     })

  #     # Creating non related account user
  #     {:ok, _} =
  #       change(%User{}, %{
  #         username: user.username,
  #         password: "test1234",
  #         account_id: account2.id,
  #         default_account_id: account2.id
  #       })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()
  #       |> Repo.insert()

  #     # Creating related account user
  #     {:error, au_changeset} =
  #       change(%User{}, %{
  #         username: user.username,
  #         password: "test1234",
  #         account_id: account1.id,
  #         default_account_id: account1.id
  #       })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()
  #       |> Repo.insert()

  #     # Creating global user
  #     {:error, gu_changeset} =
  #       change(%User{}, %{
  #         username: user.username,
  #         password: "test1234",
  #         default_account_id: account2.id
  #       })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()
  #       |> Repo.insert()

  #     assert au_changeset.valid? == false
  #     assert gu_changeset.valid? == false
  #     assert Keyword.keys(au_changeset.errors) == [:username]
  #     assert Keyword.keys(gu_changeset.errors) == [:username]
  #   end

  #   test "when action is insert and given account username already exist" do
  #     account1 = Repo.insert!(%Account{ name: Faker.Company.name() })
  #     account2 = Repo.insert!(%Account{ name: Faker.Company.name() })
  #     user = Repo.insert!(%User{
  #       username: Faker.String.base64(5),
  #       password: "test1234",
  #       account_id: account1.id,
  #       default_account_id: account1.id
  #     })

  #     # Creating global user should pass
  #     {:ok, _} =
  #       change(%User{}, %{
  #         username: user.username,
  #         password: "test1234",
  #         default_account_id: account2.id
  #       })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()
  #       |> Repo.insert()

  #     # Creating non related account user should pass
  #     {:ok, _} =
  #       change(%User{}, %{
  #         username: user.username,
  #         password: "test1234",
  #         account_id: account2.id,
  #         default_account_id: account2.id
  #       })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()
  #       |> Repo.insert()

  #     # Creating related account user should error
  #     {:error, changeset} =
  #       change(%User{}, %{
  #         username: user.username,
  #         password: "test1234",
  #         account_id: account1.id,
  #         default_account_id: account1.id
  #       })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()
  #       |> Repo.insert()

  #     assert changeset.valid? == false
  #     assert Keyword.keys(changeset.errors) == [:username]
  #   end

  #   test "when action is insert and given invalid email" do
  #     changeset =
  #       change(%User{}, %{ username: Faker.String.base64(5), email: "invalid", password: "test1234" })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()

  #     assert changeset.valid? == false
  #     assert Keyword.keys(changeset.errors) == [:email]
  #   end

  #   test "when action is insert and given global email already exist" do
  #     account1 = Repo.insert!(%Account{ name: Faker.Company.name() })
  #     account2 = Repo.insert!(%Account{ name: Faker.Company.name() })
  #     user = Repo.insert!(%User{
  #       username: Faker.String.base64(5),
  #       password: "test1234",
  #       email: Faker.Internet.email(),
  #       default_account_id: account1.id
  #     })

  #     # Creating account user should pass
  #     {:ok, _} =
  #       change(%User{}, %{
  #         username: Faker.String.base64(5),
  #         password: "test1234",
  #         email: user.email,
  #         account_id: account1.id,
  #         default_account_id: account1.id
  #       })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()
  #       |> Repo.insert()

  #     # Creating global user should error
  #     {:error, changeset} =
  #       change(%User{}, %{
  #         username: "username2",
  #         password: "test1234",
  #         email: user.email,
  #         default_account_id: account2.id
  #       })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()
  #       |> Repo.insert()

  #     assert changeset.valid? == false
  #     assert Keyword.keys(changeset.errors) == [:email]
  #   end

  #   test "when action is insert and given password less than 8 characters" do
  #     changeset =
  #       change(%User{}, %{ username: "username", password: "abc" })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()

  #     assert changeset.valid? == false
  #     assert Keyword.keys(changeset.errors) == [:password]
  #   end

  #   test "when action is insert, auth_method is tfa_sms and missing required fields" do
  #     changeset =
  #       change(%User{}, %{ auth_method: "tfa_sms", username: Faker.Internet.user_name(), password: "test1234" })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()

  #     assert changeset.valid? == false
  #     assert Keyword.keys(changeset.errors) == [:phone_verification_code, :phone_number]
  #   end

  #   test "when action is insert, auth_method is tfa_sms and phone_verification_code is invalid" do
  #     changeset =
  #       change(%User{}, %{
  #         auth_method: "tfa_sms",
  #         username: Faker.Internet.user_name(),
  #         password: "test1234",
  #         phone_number: "+11234567890",
  #         phone_verification_code: "123456"
  #       })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()

  #     assert changeset.valid? == false
  #     assert Keyword.keys(changeset.errors) == [:phone_verification_code]
  #   end

  #   test "when action is insert, auth_method is tfa_sms and all changes are valid" do
  #     account = Repo.insert!(%Account{
  #       name: Faker.Company.name()
  #     })
  #     pvc = Repo.insert!(%PhoneVerificationCode{
  #       account_id: account.id,
  #       phone_number: "+11234567890",
  #       value: "123456",
  #       expires_at: Timex.shift(Timex.now(), minutes: 5)
  #     })
  #     changeset =
  #       change(%User{}, %{
  #         auth_method: "tfa_sms",
  #         username: Faker.Internet.user_name(),
  #         password: "test1234",
  #         phone_number: pvc.phone_number,
  #         phone_verification_code: pvc.value
  #       })
  #       |> Map.put(:action, :insert)
  #       |> User.validate()

  #     assert changeset.valid? == true
  #   end

  #   test "when action is update but missing required fields" do
  #     user = %User{ username: "username" }

  #     changeset =
  #       user
  #       |> change(%{ password: "newpassword" })
  #       |> Map.put(:action, :update)
  #       |> User.validate()

  #     assert changeset.valid? == false
  #     assert Keyword.keys(changeset.errors) == [:current_password]
  #   end

  #   test "when action is update and password is changed but provided wrong current password" do
  #     user = %User{ username: "username" }

  #     changeset =
  #       user
  #       |> change(%{ password: "newpassword", current_password: "wrongpassword" })
  #       |> Map.put(:action, :update)
  #       |> User.validate()

  #     assert changeset.valid? == false
  #     assert Keyword.keys(changeset.errors) == [:current_password]
  #   end

  #   test "when action is update" do
  #     user = %User{ username: Faker.String.base64(5) }

  #     changeset =
  #       user
  #       |> change(%{})
  #       |> Map.put(:action, :update)
  #       |> User.validate()

  #     assert changeset.valid?
  #   end
  # end

  describe "changeset/3" do
    test "when action is insert" do
      account = Repo.insert!(%Account{ default_auth_method: "tfa_sms" })
      params = %{
        username: " Tes t ",
        email: " te s t@example.com  ",
        password: "test1234",
        phone_verification_code: "123456",
        first_name: "Roy",
        last_name: "Bao"
      }

      changeset =
        %User{ account_id: account.id, account: account }
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
        %User{ }
        |> User.changeset(:update, params)

      assert changeset.changes[:encrypted_password]
      assert changeset.changes[:username] == "test"
      assert changeset.changes[:email] == "test@example.com"
      assert changeset.changes[:name] == "Roy Bao"
    end
  end

  describe "delete_all_pvc/1" do
    test "when user has phone verification code" do
      account = Repo.insert!(%Account{})
      pvc = Repo.insert!(%PhoneVerificationCode{
        account_id: account.id,
        phone_number: Faker.Phone.EnUs.phone(),
        value: "123456",
        expires_at: Timex.now()
      })
      user = %User{ phone_number: pvc.phone_number, phone_verification_code: pvc.value }

      User.delete_all_pvc(user)

      refute Repo.get(PhoneVerificationCode, pvc.id)
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
      user = %User{ id: Ecto.UUID.generate() }
      account = %Account{ id: Ecto.UUID.generate() }

      assert User.get_role(user, account.id) == nil
    end
  end

  describe "get_tfa_code/1" do
    test "when tfa code expired" do
      user = %User{ tfa_code: "123456", tfa_code_expires_at: Timex.now() }

      assert User.get_tfa_code(user) == nil
    end

    test "when tfa code is valid" do
      user = %User{ tfa_code: "123456", tfa_code_expires_at: Timex.shift(Timex.now(), minutes: 1) }

      assert User.get_tfa_code(user) == "123456"
    end
  end

  test "refresh_tfa_code/1" do
    account = Repo.insert!(%Account{
      name: Faker.Company.name()
    })
    user = Repo.insert!(%User{
      username: Faker.String.base64(5),
      default_account_id: account.id
    })

    user = User.refresh_tfa_code(user)

    assert user.tfa_code
    assert user.tfa_code_expires_at
  end

  test "clear_tfa_code/1" do
    account = Repo.insert!(%Account{
      name: Faker.Company.name()
    })
    user = Repo.insert!(%User{
      username: Faker.String.base64(5),
      default_account_id: account.id,
      tfa_code: "123456",
      tfa_code_expires_at: Timex.now()
    })

    user = User.clear_tfa_code(user)

    assert user.tfa_code == nil
    assert user.tfa_code_expires_at == nil
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

  test "update_password/2" do
    account = Repo.insert!(%Account{
      name: Faker.Company.name()
    })
    user = Repo.insert!(%User{
      username: Faker.String.base64(5),
      default_account_id: account.id
    })

    user = User.update_password(user, "test1234")

    assert user.encrypted_password
  end
end
