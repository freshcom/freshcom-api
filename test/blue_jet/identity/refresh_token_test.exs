defmodule BlueJet.Identity.RefreshTokenTest do
  use BlueJet.DataCase

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.User
  alias BlueJet.Identity.RefreshToken

  describe "schema" do
    test "when account is deleted its refresh token should automatically be removed" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account.id
      })

      Repo.delete!(account)
      refute Repo.get(RefreshToken, refresh_token.id)
    end

    test "when user is deleted its refresh token should automatically be removed" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name()
      })
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        default_account_id: account.id
      })
      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account.id,
        user_id: user.id
      })

      Repo.delete!(user)
      refute Repo.get(RefreshToken, refresh_token.id)
    end
  end

  describe "get_prefixed_id/1" do
    test "when its a prt and account is in test mode" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name(),
        mode: "test"
      })
      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account.id
      })

      assert RefreshToken.get_prefixed_id(refresh_token) == "prt-test-#{refresh_token.id}"
    end

    test "when its a prt and account is in live mode" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name(),
        mode: "live"
      })
      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account.id
      })

      assert RefreshToken.get_prefixed_id(refresh_token) == "prt-live-#{refresh_token.id}"
    end

    test "when its a urt and account is in test mode" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name(),
        mode: "test"
      })
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        default_account_id: account.id
      })
      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account.id,
        user_id: user.id
      })

      assert RefreshToken.get_prefixed_id(refresh_token) == "urt-test-#{refresh_token.id}"
    end

    test "when its a urt and account is in live mode" do
      account = Repo.insert!(%Account{
        name: Faker.Company.name(),
        mode: "live"
      })
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        default_account_id: account.id
      })
      refresh_token = Repo.insert!(%RefreshToken{
        account_id: account.id,
        user_id: user.id
      })

      assert RefreshToken.get_prefixed_id(refresh_token) == "urt-live-#{refresh_token.id}"
    end
  end

  test "unprefix_id/1" do
    assert RefreshToken.unprefix_id("prt-test-theid") == "theid"
    assert RefreshToken.unprefix_id("prt-live-theid") == "theid"
    assert RefreshToken.unprefix_id("urt-test-theid") == "theid"
    assert RefreshToken.unprefix_id("urt-live-theid") == "theid"
  end

  describe "sign_token/1" do
    test "with valid claims" do
      signed_token = RefreshToken.sign_token(%{ "c1" => "c1" })

      assert signed_token
    end
  end

  describe "verify_token/1" do
    test "with valid signed token" do
      signed_token = RefreshToken.sign_token(%{ "c1" => "c1" })
      {true, verified_token} = RefreshToken.verify_token(signed_token)

      assert verified_token
      assert verified_token["c1"] == "c1"
    end
  end
end
