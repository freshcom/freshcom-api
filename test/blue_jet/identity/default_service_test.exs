defmodule BlueJet.Identity.DefaultDefaultServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.DefaultService
  alias BlueJet.Identity.{User, Account, AccountMembership, RefreshToken, PhoneVerificationCode}

  describe "get_account/1" do
    test "when only account_id is given" do
      account = Repo.insert!(%Account{})

      assert DefaultService.get_account(%{ account_id: nil }) == nil
      assert DefaultService.get_account(%{ account_id: account.id }).id == account.id
    end

    test "when only account is given" do
      account = Repo.insert!(%Account{})

      assert DefaultService.get_account(%{ account: nil }) == nil
      assert DefaultService.get_account(%{ account: account }) == account
    end

    test "when both account and account_id is given but account is nil" do
      account = Repo.insert!(%Account{})

      assert DefaultService.get_account(%{ account_id: account.id, account: nil }).id == account.id
    end

    test "when both account and account_id is given and account is not nil" do
      account = Repo.insert!(%Account{})

      assert DefaultService.get_account(%{ account_id: account.id, account: account }) == account
    end
  end

  describe "create_account/1" do
    test "when given fields are invalid" do
      {:error, changeset} = DefaultService.create_account(%{})

      assert changeset.valid? == false
    end

    test "when fields are valid" do
      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity.account.create.success"
          assert data[:account]
          assert data[:test_account]

          {:ok, nil}
         end)

      {:ok, account} = DefaultService.create_account(%{ "name" => Faker.Company.name() })
      test_account = account.test_account

      assert account.mode == "live"
      assert test_account.mode == "test"
      assert Repo.get_by(RefreshToken, account_id: account.id)
      assert Repo.get_by(RefreshToken, account_id: test_account.id)
    end
  end

  describe "update_account/2" do
    test "when given fields are invalid" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Account{
        name: Faker.Company.name(),
        live_account_id: account.id,
        mode: "test"
      })

      {:error, changeset} = DefaultService.update_account(account, %{ name: nil })

      assert changeset.valid? == false
    end

    test "when given fields are valid" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Account{
        name: Faker.Company.name(),
        live_account_id: account.id,
        mode: "test"
      })
      fields = %{
        "name" => Faker.Company.name(),
        "company_name" => Faker.Company.name(),
        "default_auth_method" => "tfa_sms",
        "website_url" => Faker.Internet.url(),
        "support_email" => Faker.Internet.email(),
        "tech_email" => Faker.Internet.email(),
        "caption" => Faker.Lorem.sentence(5),
        "description" => Faker.Lorem.sentence(20)
      }

      {:ok, account} = DefaultService.update_account(account, fields)
      test_account = account.test_account

      assert account.name == fields["name"]
      assert account.company_name == fields["company_name"]
      assert account.default_auth_method == fields["default_auth_method"]
      assert account.website_url == fields["website_url"]
      assert account.support_email == fields["support_email"]
      assert account.tech_email == fields["tech_email"]
      assert account.caption == fields["caption"]
      assert account.description == fields["description"]

      assert test_account.name == fields["name"]
      assert test_account.company_name == fields["company_name"]
      assert test_account.default_auth_method == fields["default_auth_method"]
      assert test_account.website_url == fields["website_url"]
      assert test_account.support_email == fields["support_email"]
      assert test_account.tech_email == fields["tech_email"]
      assert test_account.caption == fields["caption"]
      assert test_account.description == fields["description"]
    end
  end

  test "reset_account/1" do
    account = Repo.insert!(%Account{ mode: "test" })
    user = Repo.insert!(%User{
      account_id: account.id,
      default_account_id: account.id,
      username: Faker.Internet.user_name()
    })
    EventHandlerMock
    |> expect(:handle_event, fn(event_name, _) ->
        assert event_name == "identity.account.reset.success"
        {:ok, nil}
       end)

    {:ok, account} = DefaultService.reset_account(account)

    assert Repo.get(Account, account.id)
    refute Repo.get(User, user.id)
  end

  describe "create_user/2" do
    test "when fields given is invalid and account is nil" do
      {:error, changeset} = DefaultService.create_user(%{}, %{ account: nil })

      assert changeset.valid? == false
    end

    test "when fields given is invalid and account is valid" do
      account = Repo.insert!(%Account{ name: Faker.Company.name() })

      {:error, changeset} = DefaultService.create_user(%{}, %{ account: account })

      assert changeset.valid? == false
    end

    test "when fields given is valid and account is nil" do
      EventHandlerMock
      |> expect(:handle_event, fn(event_name, _) ->
          assert event_name == "identity.account.create.success"
          {:ok, nil}
         end)
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity.user.create.success"
          assert data[:user]
          assert data[:account] == nil

          {:ok, nil}
         end)
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity.email_verification_token.create.success"
          assert data[:user]
          assert data[:account] == nil

          {:ok, nil}
         end)

      fields = %{
        "account_name" => Faker.Name.name(),
        "username" => Faker.Internet.user_name(),
        "password" => "test1234"
      }

      {:ok, user} = DefaultService.create_user(fields, %{ account: nil })


      assert user
      assert user.account == nil
      assert user.default_account.id
      assert Repo.get_by(AccountMembership, account_id: user.default_account.id, user_id: user.id, role: "administrator")
    end

    test "when fields are valid and account is valid" do
      account = Repo.insert!(%Account{})
      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity.user.create.success"
          assert data[:user]
          assert data[:account]

          {:ok, nil}
         end)
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity.email_verification_token.create.success"
          assert data[:user]
          assert data[:account]

          {:ok, nil}
         end)

      fields = %{
        "username" => Faker.Internet.user_name(),
        "email" => Faker.Internet.safe_email(),
        "password" => "test1234",
        "role" => "customer"
      }

      {:ok, user} = DefaultService.create_user(fields, %{ account: account })

      assert user
      assert user.account.id == account.id
      assert user.default_account.id == account.id
      assert Repo.get_by(AccountMembership, account_id: user.default_account.id, user_id: user.id, role: "customer")
    end
  end

  describe "update_user/3" do
    test "when user is given and fields are invalid" do
      {:error, changeset} = DefaultService.update_user(%User{}, %{ username: nil }, %{ account: %Account{} })

      assert changeset.valid? == false
    end

    # Issue: GL#24
    test "when event handler returns error" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.user_name(),
        password: "test1234",
        email: Faker.Internet.safe_email()
      })
      fields = %{
        email: nil
      }

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.user.update.success"

          {:error, %{ errors: [email: {"can't be blank", [validation: :required]}] }}
         end)

      {:error, changeset} = DefaultService.update_user(user.id, fields, %{ account: account })
      assert changeset.errors
    end

    test "when user is given and fields are valid" do
      account = Repo.insert!(%Account{})
      pvc = Repo.insert!(%PhoneVerificationCode{
        account_id: account.id,
        phone_number: Faker.Phone.EnUs.phone(),
        value: "123456",
        expires_at: Timex.shift(Timex.now(), minutes: 5)
      })
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.user_name(),
        password: "test1234"
      })
      fields = %{
        phone_number: pvc.phone_number,
        phone_verification_code: pvc.value
      }

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.user.update.success"
          {:ok, nil}
         end)

      {:ok, user} = DefaultService.update_user(user.id, fields, %{ account: account })

      assert user.phone_number == fields.phone_number
      refute Repo.get(PhoneVerificationCode, pvc.id)
    end
  end

  describe "get_user/2" do
    test "when fields are valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.user_name(),
        password: "test1234"
      })
      Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: target_user.id,
        role: "administrator"
      })

      user = DefaultService.get_user(%{ id: target_user.id }, %{ account: account })

      assert user.id == target_user.id
    end
  end

  describe "delete_user/2" do
    test "when id is valid" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.user_name(),
        password: "test1234"
      })

      {:ok, user} = DefaultService.delete_user(user.id, %{ account: account })

      refute Repo.get(User, user.id)
    end
  end

  describe "create_email_verification_token/1" do
    test "when user is nil" do
      assert DefaultService.create_email_verification_token(nil) == {:error, :not_found}
    end

    test "when user is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })
      Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: target_user.id,
        role: "administrator"
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.email_verification_token.create.success"
          {:ok, nil}
         end)

      {:ok, user} = DefaultService.create_email_verification_token(target_user)

      assert user.email_verification_token
      assert user.email_verified == false
      assert user.id == target_user.id
    end
  end

  describe "create_email_verification_token/2" do
    test "when user_id is nil" do
      assert DefaultService.create_email_verification_token(%{ "user_id" => nil }, %{}) == {:error, :not_found}
    end

    test "when account is given and user_id does not exist" do
      account = Repo.insert!(%Account{})
      assert DefaultService.create_email_verification(%{ "user_id" => Faker.Internet.email() }, %{ account: account }) == {:error, :not_found}
    end

    test "when account is nil and user_id does not exist" do
      assert DefaultService.create_email_verification(%{ "user_id" => Faker.Internet.email() }, %{ account: nil }) == {:error, :not_found}
    end

    test "when account is given and user_id is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email: Faker.Internet.email()
      })
      Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: target_user.id,
        role: "administrator"
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.email_verification_token.create.success"
          {:ok, nil}
         end)

      {:ok, user} = DefaultService.create_email_verification_token(%{ "user_id" => target_user.id }, %{ account: account })
      assert user.id == target_user.id
      assert user.email_verification_token
    end

    test "when account is nil and email is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email: Faker.Internet.email()
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.email_verification_token.create.success"
          {:ok, nil}
         end)

      {:ok, user} = DefaultService.create_email_verification_token(%{ "user_id" => target_user.id }, %{ account: nil })
      assert user.id == target_user.id
      assert user.email_verification_token
    end
  end

  describe "create_email_verification/2" do
    test "when token is nil" do
      assert DefaultService.create_email_verification(%{ "token" => nil }, %{}) == {:error, :not_found}
    end

    test "when account is given and token does not exist" do
      account = Repo.insert!(%Account{})
      assert DefaultService.create_email_verification(%{ "token" => Ecto.UUID.generate() }, %{ account: account }) == {:error, :not_found}
    end

    test "when account is nil and token does not exist" do
      assert DefaultService.create_email_verification(%{ "token" => Ecto.UUID.generate() }, %{ account: nil }) == {:error, :not_found}
    end

    test "when account is given and token is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email_verification_token: Ecto.UUID.generate()
      })

      {:ok, user} = DefaultService.create_email_verification(%{ "token" => target_user.email_verification_token }, %{ account: account })
      assert target_user.id == user.id
    end

    test "when account is nil and token is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email_verification_token: Ecto.UUID.generate()
      })

      {:ok, user} = DefaultService.create_email_verification(%{ "token" => target_user.email_verification_token }, %{ account: nil })
      assert target_user.id == user.id
    end
  end

  describe "create_email_verification/1" do
    test "when user is nil" do
      assert DefaultService.create_email_verification(nil) == {:error, :not_found}
    end

    test "when user is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email_verification_token: Ecto.UUID.generate()
      })

      {:ok, user} = DefaultService.create_email_verification(target_user)
      assert target_user.id == user.id
    end
  end

  describe "create_password_reset_token/2" do
    test "when username is not provided" do
      {:error, changeset} = DefaultService.create_password_reset_token(%{ "username" => "" }, %{})

      assert changeset.valid? == false
    end

    test "when username does not belong to any user" do
      EventHandlerMock
      |> expect(:handle_event, fn(event_name, _) ->
          assert event_name == "identity.password_reset_token.create.error.username_not_found"

          {:ok, nil}
         end)

      {:error, :not_found} = DefaultService.create_password_reset_token(%{ "username" => Faker.Internet.safe_email() }, %{})
    end

    test "when username belongs to a user" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.user_name(),
        email: Faker.Internet.safe_email()
      })
      Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: user.id,
        role: "administrator"
      })

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity.password_reset_token.create.success"
          assert data[:user]
          assert data[:account]

          {:ok, nil}
         end)

      {:ok, user} = DefaultService.create_password_reset_token(%{ "username" => user.username }, %{ account: account })

      assert user.password_reset_token
    end
  end

  describe "update_password/3" do
    test "when password_reset_token is invalid" do
      account = Repo.insert!(%Account{})

      {:error, :not_found} = DefaultService.update_password(%{ reset_token: "invalid" }, "test1234", %{ account: account })
    end

    test "when password_reset_token is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.user_name(),
        email: Faker.Internet.safe_email(),
        password_reset_token: "token",
        encrypted_password: "original"
      })

      {:ok, password} = DefaultService.update_password(%{ reset_token: "token" }, "test1234", %{ account: account })
      assert password.encrypted_value != target_user.encrypted_password
    end

    test "when password provided is invalid" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.user_name(),
        email: Faker.Internet.safe_email(),
        password_reset_token: "token",
        encrypted_password: "original"
      })

      {:error, changeset} = DefaultService.update_password(%{ reset_token: "token" }, "test", %{ account: account })

      assert changeset.valid? == false
      assert changeset.changes[:value]
    end
  end

  describe "create_phone_verification_code/2" do
    test "when given invalid fields" do
      {:error, changeset} = DefaultService.create_phone_verification_code(%{}, %{ account: %Account{} })

      assert changeset.valid? == false
    end

    test "when given valid fields" do
      account = Repo.insert!(%Account{})
      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity.phone_verification_code.create.success"
          assert data[:phone_verification_code]
          assert data[:account]

          {:ok, nil}
         end)

      {:ok, pvc} = DefaultService.create_phone_verification_code(%{ phone_number: "+11234567890" }, %{ account: account })

      assert pvc.value
    end
  end

  test "get_refresh_token/1" do
    account = Repo.insert!(%Account{})
    target_refresh_token = Repo.insert!(%RefreshToken{ account_id: account.id })

    refresh_token = DefaultService.get_refresh_token(%{ account: account })

    assert refresh_token
    assert refresh_token.id == target_refresh_token.id
    assert refresh_token.prefixed_id
  end
end
