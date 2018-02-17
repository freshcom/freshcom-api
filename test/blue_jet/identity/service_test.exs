defmodule BlueJet.Identity.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Service
  alias BlueJet.Identity.{User, Account}

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
          assert name == "identity.email_confirmation_token.after_create"
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
          assert name == "identity.email_confirmation_token.after_create"
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
          assert name == "identity.email_confirmation_token.after_create"
          {:ok, nil}
         end)

      {:ok, user} = Service.create_email_confirmation_token(%{ "email" => target_user.email }, %{ account: nil })
      assert user.id == target_user.id
      assert user.email_confirmation_token
    end
  end
end
