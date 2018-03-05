defmodule BlueJet.Identity.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Service
  alias BlueJet.Identity.{User, Account, AccountMembership, RefreshToken}

  setup :verify_on_exit!

  describe "get_account/1" do
    test "when only account_id is given" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })

      assert Service.get_account(%{ account_id: nil }) == nil
      assert Service.get_account(%{ account_id: account.id }).id == account.id
    end

    test "when only account is given" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })

      assert Service.get_account(%{ account: nil }) == nil
      assert Service.get_account(%{ account: account }) == account
    end

    test "when both account and account_id is given but account is nil" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })

      assert Service.get_account(%{ account_id: account.id, account: nil }).id == account.id
    end

    test "when both account and account_id is given and account is not nil" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })

      assert Service.get_account(%{ account_id: account.id, account: account }) == account
    end
  end

  describe "create_account/1" do
    test "when given fields are invalid" do
      {:error, changeset} = Service.create_account(%{})

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

      {:ok, account} = Service.create_account(%{ "name" => Faker.Company.name() })
      test_account = account.test_account

      assert account.mode == "live"
      assert test_account.mode == "test"
      assert Repo.get_by(RefreshToken, account_id: account.id)
      assert Repo.get_by(RefreshToken, account_id: test_account.id)
    end
  end

  describe "update_account/2" do
    test "when given fields are invalid" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
      Repo.insert!(%Account{
        name: Faker.Company.name(),
        live_account_id: account.id,
        mode: "test"
      })

      {:error, changeset} = Service.update_account(account, %{ name: nil })

      assert changeset.valid? == false
    end

    test "when given fields are valid" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
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

      {:ok, account} = Service.update_account(account, fields)
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

  describe "create_user/2" do
    test "when fields given is invalid and account is nil" do
      {:error, changeset} = Service.create_user(%{}, %{ account: nil })

      assert changeset.valid? == false
    end

    test "when fields given is invalid and account is valid" do
      account = Repo.insert!(%Account{ name: Faker.Company.name() })

      {:error, changeset} = Service.create_user(%{}, %{ account: account })

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

      {:ok, user} = Service.create_user(fields, %{ account: nil })


      assert user
      assert user.account == nil
      assert user.default_account.id
      assert Repo.get_by(AccountMembership, account_id: user.default_account.id, user_id: user.id, role: "administrator")
    end

    test "when fields are valid and account is valid" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
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

      {:ok, user} = Service.create_user(fields, %{ account: account })

      assert user
      assert user.account.id == account.id
      assert user.default_account.id == account.id
      assert Repo.get_by(AccountMembership, account_id: user.default_account.id, user_id: user.id, role: "customer")
    end
  end

  describe "create_email_verification/2" do
    test "when token is nil" do
      assert Service.create_email_verification(%{ "token" => nil }, %{}) == {:error, :not_found}
    end

    test "when account is given and token does not exist" do
      account = Repo.insert!(%Account{})
      assert Service.create_email_verification(%{ "token" => Ecto.UUID.generate() }, %{ account: account }) == {:error, :not_found}
    end

    test "when account is nil and token does not exist" do
      assert Service.create_email_verification(%{ "token" => Ecto.UUID.generate() }, %{ account: nil }) == {:error, :not_found}
    end

    test "when account is given and token is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email_verification_token: Ecto.UUID.generate()
      })

      {:ok, user} = Service.create_email_verification(%{ "token" => target_user.email_verification_token }, %{ account: account })
      assert target_user.id == user.id
    end

    test "when account is nil and token is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email_verification_token: Ecto.UUID.generate()
      })

      {:ok, user} = Service.create_email_verification(%{ "token" => target_user.email_verification_token }, %{ account: nil })
      assert target_user.id == user.id
    end
  end

  describe "create_email_verification/1" do
    test "when user is nil" do
      assert Service.create_email_verification(nil) == {:error, :not_found}
    end

    test "when user is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email_verification_token: Ecto.UUID.generate()
      })

      {:ok, user} = Service.create_email_verification(target_user)
      assert target_user.id == user.id
    end
  end

  describe "create_email_verification_token/1" do
    test "when user is nil" do
      assert Service.create_email_verification_token(nil) == {:error, :not_found}
    end

    test "when user is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.email_verification_token.create.success"
          {:ok, nil}
         end)

      {:ok, user} = Service.create_email_verification_token(target_user)

      assert user.email_verification_token
      assert user.id == target_user.id
    end
  end

  describe "create_email_verification_token/2" do
    test "when email is nil" do
      assert Service.create_email_verification_token(%{ "email" => nil }, %{}) == {:error, :not_found}
    end

    test "when account is given and email does not exist" do
      account = Repo.insert!(%Account{})
      assert Service.create_email_verification(%{ "email" => Faker.Internet.email() }, %{ account: account }) == {:error, :not_found}
    end

    test "when account is nil and email does not exist" do
      assert Service.create_email_verification(%{ "email" => Faker.Internet.email() }, %{ account: nil }) == {:error, :not_found}
    end

    test "when account is given and email is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email: Faker.Internet.email()
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.email_verification_token.create.success"
          {:ok, nil}
         end)

      {:ok, user} = Service.create_email_verification_token(%{ "email" => target_user.email }, %{ account: account })
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

      {:ok, user} = Service.create_email_verification_token(%{ "email" => target_user.email }, %{ account: nil })
      assert user.id == target_user.id
      assert user.email_verification_token
    end
  end
end
