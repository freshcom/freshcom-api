defmodule BlueJet.AuthenticationTest do
  use BlueJet.ModelCase

  alias BlueJet.Authentication
  alias BlueJet.Registration
  alias BlueJet.RefreshToken
  alias BlueJet.User
  alias BlueJet.Repo

  setup do
    {_, %User{ default_account_id: account1_id, id: user1_id }} = Registration.sign_up(%{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: "test1@example.com",
      password: "test1234",
      account_name: Faker.Company.name()
    })
    account1_rt = from(r in RefreshToken, where: r.account_id == ^account1_id and is_nil(r.user_id)) |> Repo.one()
    user1_rt = Repo.get_by(RefreshToken, account_id: account1_id, user_id: user1_id)

    {_, %User{ default_account_id: account2_id, id: user2_id }} = Registration.sign_up(%{
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
       account2_rt: account2_rt.id,
       user2_rt: user2_rt.id }
  end

  describe "get_token/2" do
    test "with no username and password and no access_token" do
      {:error, %{ error: error }} = Authentication.get_token(%{}, nil)

      assert error == :invalid_request
    end

    test "with username and password and no access_token" do
      {:ok, token} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234"}, nil)

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token
    end

    test "with empty refresh_token and no access_token" do
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: "" }, nil)
      assert error == :invalid_grant
    end

    test "with invalid refresh_token and no access_token" do
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: "invalid" }, nil)
      assert error == :invalid_grant
    end

    test "with invalid refresh_token and valid user access_token" do
      {:ok, %{ access_token: access_token }} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234" }, nil)
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: "invalid" }, access_token)

      assert error == :invalid_grant
    end

    test "with valid account refresh_token and no access_token", %{ account1_rt: account1_rt } do
      {:ok, token} = Authentication.get_token(%{ refresh_token: account1_rt }, nil)

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token
    end

    test "with valid account refresh_token and invalid access_token", %{ account1_rt: account1_rt } do
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: account1_rt }, "invalid")

      assert error == :invalid_client
    end

    test "with valid account refresh_token and user access_token", %{ account1_rt: account1_rt } do
      {:ok, %{ access_token: access_token }} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234" }, nil)
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: account1_rt }, access_token)

      assert error == :invalid_client
    end

    test "with valid user refresh_token and no access_token", %{ user1_rt: user1_rt } do
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: user1_rt }, nil)

      assert error == :invalid_client
    end

    test "with valid user refresh_token and invalid access_token", %{ user1_rt: user1_rt } do
      {:error, %{ error: error }} = Authentication.get_token(%{ refresh_token: user1_rt }, "invalid")

      assert error == :invalid_client
    end

    test "with valid user refresh_token and valid user access_token", %{ user1_rt: user1_rt } do
      {:ok, %{ access_token: access_token }} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234" }, nil)
      {:ok, token} = Authentication.get_token(%{ refresh_token: user1_rt }, access_token)

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token
    end
  end

  # describe "get_jwt/1" do
  #   test "with valid credentials" do
  #     {:ok, token} = Authentication.get_token(%{ username: "test1@example.com", password: "test1234" })

  #     assert token.access_token
  #     assert token.token_type
  #     assert token.expires_in
  #     assert token.refresh_token
  #   end

  #   test "with missing credentials" do
  #     {:error, _} = Authentication.get_token(%{ password: "test1234" })
  #   end

  #   test "with invalid credentials" do
  #     {:error, _} = Authentication.get_token(%{ username: "invalid", password: "invalid" })
  #   end
  # end
end
