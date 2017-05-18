defmodule BlueJet.AuthenticationTest do
  use BlueJet.ModelCase

  alias BlueJet.Authentication
  alias BlueJet.UserRegistration
  alias BlueJet.RefreshToken
  alias BlueJet.User
  alias BlueJet.Repo

  setup do
    {_, %User{ default_account_id: account1_id, id: user1_id }} = UserRegistration.sign_up(%{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: "test1@example.com",
      password: "test1234",
      account_name: Faker.Company.name()
    })
    account1_rt = from(r in RefreshToken, where: r.account_id == ^account1_id and is_nil(r.user_id)) |> Repo.one()
    user1_rt = Repo.get_by(RefreshToken, account_id: account1_id, user_id: user1_id)

    {_, %User{ default_account_id: account2_id, id: user2_id }} = UserRegistration.sign_up(%{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: "test2@example.com",
      password: "test1234",
      account_name: Faker.Company.name()
    })
    account2_rt = from(r in RefreshToken, where: r.account_id == ^account2_id and is_nil(r.user_id)) |> Repo.one()
    user2_rt = Repo.get_by(RefreshToken, account_id: account2_id, user_id: user2_id)

    %{ account1_rt: account1_rt.id,
       user1_rt: user1_rt.id,
       account1_id: account1_id,
       user1_id: user1_id
    }
  end

  describe "get_token/2" do
    test "with no username and password and no vas" do
      {:error, %{ error: error }} = Authentication.get_token(%{}, nil)

      assert error == :invalid_request
    end

    test "with username and password and no vas" do
      {:ok, token} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234"}, nil)

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token
    end

    test "with empty refresh_token and no vas" do
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: "" }, nil)
      assert error == :invalid_grant
    end

    test "with invalid refresh_token and no vas" do
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: "invalid" }, nil)
      assert error == :invalid_grant
    end

    test "with invalid refresh_token and valid user vas", %{ account1_id: account1_id, user1_id: user1_id } do
      {:ok, %{ access_token: access_token }} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234" }, nil)
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: "invalid" }, %{ account_id: account1_id, user_id: user1_id })

      assert error == :invalid_grant
    end

    test "with valid account refresh_token and no vas", %{ account1_rt: account1_rt } do
      {:ok, token} = Authentication.get_token(%{ refresh_token: account1_rt }, nil)

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token
    end

    test "with valid account refresh_token and user vas", %{ account1_rt: account1_rt, account1_id: account1_id, user1_id: user1_id } do
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: account1_rt }, %{ account_id: account1_id, user_id: user1_id })

      assert error == :invalid_client
    end

    test "with valid user refresh_token and no vas", %{ user1_rt: user1_rt } do
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: user1_rt }, nil)

      assert error == :invalid_client
    end

    test "with valid user refresh_token and valid user vas", %{ user1_rt: user1_rt, account1_id: account1_id, user1_id: user1_id } do
      {:ok, %{ access_token: access_token }} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234" }, nil)
      {:ok, token} = Authentication.get_token(%{ refresh_token: user1_rt }, %{ account_id: account1_id, user_id: user1_id })

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token
    end
  end
end
