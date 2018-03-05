defmodule BlueJet.Identity.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Service
  alias BlueJet.Identity.{User, Account, RefreshToken}

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

      {:ok, account} = Service.create_account(%{ name: Faker.Company.name() })
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
      test_account = Repo.insert!(%Account{
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
      test_account = Repo.insert!(%Account{
        name: Faker.Company.name(),
        live_account_id: account.id,
        mode: "test"
      })
      fields = %{
        name: Faker.Company.name(),
        company_name: Faker.Company.name(),
        default_auth_method: "tfa_sms",
        website_url: Faker.Internet.url(),
        support_email: Faker.Internet.email(),
        tech_email: Faker.Internet.email(),
        caption: Faker.Lorem.sentence(5),
        description: Faker.Lorem.sentence(20)
      }

      {:ok, account} = Service.update_account(account, fields)
      test_account = account.test_account

      assert account.name == fields.name
      assert account.company_name == fields.company_name
      assert account.default_auth_method == fields.default_auth_method
      assert account.website_url == fields.website_url
      assert account.support_email == fields.support_email
      assert account.tech_email == fields.tech_email
      assert account.caption == fields.caption
      assert account.description == fields.description

      assert test_account.name == fields.name
      assert test_account.company_name == fields.company_name
      assert test_account.default_auth_method == fields.default_auth_method
      assert test_account.website_url == fields.website_url
      assert test_account.support_email == fields.support_email
      assert test_account.tech_email == fields.tech_email
      assert test_account.caption == fields.caption
      assert test_account.description == fields.description
    end
  end

  describe "create_email_confirmation/2" do
    test "when token is nil" do
      assert Service.create_email_confirmation(%{ "token" => nil }, %{}) == {:error, :not_found}
    end

    test "when account is given and token does not exist" do
      account = Repo.insert!(%Account{})
      assert Service.create_email_confirmation(%{ "token" => Ecto.UUID.generate() }, %{ account: account }) == {:error, :not_found}
    end

    test "when account is nil and token does not exist" do
      assert Service.create_email_confirmation(%{ "token" => Ecto.UUID.generate() }, %{ account: nil }) == {:error, :not_found}
    end

    test "when account is given and token is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email_confirmation_token: Ecto.UUID.generate()
      })

      {:ok, user} = Service.create_email_confirmation(%{ "token" => target_user.email_confirmation_token }, %{ account: account })
      assert target_user.id == user.id
    end

    test "when account is nil and token is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email_confirmation_token: Ecto.UUID.generate()
      })

      {:ok, user} = Service.create_email_confirmation(%{ "token" => target_user.email_confirmation_token }, %{ account: nil })
      assert target_user.id == user.id
    end
  end

  describe "create_email_confirmation/1" do
    test "when user is nil" do
      assert Service.create_email_confirmation(nil) == {:error, :not_found}
    end

    test "when user is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5),
        email_confirmation_token: Ecto.UUID.generate()
      })

      {:ok, user} = Service.create_email_confirmation(target_user)
      assert target_user.id == user.id
    end
  end

  describe "create_email_confirmation_token/1" do
    test "when user is nil" do
      assert Service.create_email_confirmation_token(nil) == {:error, :not_found}
    end

    test "when user is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.email_confirmation_token.create.success"
          {:ok, nil}
         end)

      {:ok, user} = Service.create_email_confirmation_token(target_user)

      assert user.email_confirmation_token
      assert user.id == target_user.id
    end
  end

  describe "create_email_confirmation_token/2" do
    test "when email is nil" do
      assert Service.create_email_confirmation_token(%{ "email" => nil }, %{}) == {:error, :not_found}
    end

    test "when account is given and email does not exist" do
      account = Repo.insert!(%Account{})
      assert Service.create_email_confirmation(%{ "email" => Faker.Internet.email() }, %{ account: account }) == {:error, :not_found}
    end

    test "when account is nil and email does not exist" do
      assert Service.create_email_confirmation(%{ "email" => Faker.Internet.email() }, %{ account: nil }) == {:error, :not_found}
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
          assert name == "identity.email_confirmation_token.create.success"
          {:ok, nil}
         end)

      {:ok, user} = Service.create_email_confirmation_token(%{ "email" => target_user.email }, %{ account: account })
      assert user.id == target_user.id
      assert user.email_confirmation_token
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
          assert name == "identity.email_confirmation_token.create.success"
          {:ok, nil}
         end)

      {:ok, user} = Service.create_email_confirmation_token(%{ "email" => target_user.email }, %{ account: nil })
      assert user.id == target_user.id
      assert user.email_confirmation_token
    end
  end
end
