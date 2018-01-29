defmodule BlueJet.Identity.ServiceTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Service
  alias BlueJet.Identity.{User, Account, AccountMembership, RefreshToken}

  describe "create_email_confirmation/2" do
    test "when token is nil" do
      assert Service.create_email_confirmation(%{ "token" => nil }, %{}) == {:error, :not_found}
    end

    test "when given account and token does not exist" do
      account = Repo.insert!(%Account{})
      assert Service.create_email_confirmation(%{ "token" => Ecto.UUID.generate() }, %{ account: account }) == {:error, :not_found}
    end

    test "when account is nil and token does not exist" do
      assert Service.create_email_confirmation(%{ "token" => Ecto.UUID.generate() }, %{ account: nil }) == {:error, :not_found}
    end

    test "when given account and token is valid" do
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
end
