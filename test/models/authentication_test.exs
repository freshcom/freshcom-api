defmodule BlueJet.AuthenticationTest do
  use BlueJet.ModelCase

  alias BlueJet.Authentication
  alias BlueJet.UserRegistration
  alias BlueJet.CustomerRegistration
  alias BlueJet.RefreshToken
  alias BlueJet.User
  alias BlueJet.Customer
  alias BlueJet.Repo

  setup do
    {_, %User{ default_account_id: account1_id, id: user1_id }} = UserRegistration.sign_up(%{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: "user1@example.com",
      password: "test1234",
      account_name: Faker.Company.name()
    })
    account1_rt = from(r in RefreshToken, where: r.account_id == ^account1_id and is_nil(r.user_id)) |> Repo.one()
    user1_rt = Repo.get_by(RefreshToken, account_id: account1_id, user_id: user1_id)

    {_, %Customer{ id: customer1_id }} = CustomerRegistration.sign_up(%{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: "customer1@example.com",
      password: "test1234",
      account_id: account1_id
    })
    customer1_rt = Repo.get_by(RefreshToken, account_id: account1_id, customer_id: customer1_id)

    %{ account1_rt: account1_rt.id,
       user1_rt: user1_rt.id,
       account1_id: account1_id,
       user1_id: user1_id,
       customer1_rt: customer1_rt.id,
       customer1_id: customer1_id
    }
  end

  describe "get_token/2" do
    test "with no credentials, no scope and no vas" do
      {:error, %{ error: error }} = Authentication.get_token(%{}, nil)

      assert error == :invalid_request
    end

    test "with valid user credentials, scope=user and no vas" do
      {:ok, token} = Authentication.get_token(%{ username: "user1@example.com", password: "test1234", scope: "user" }, nil)

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token
    end

    test "with valid customer credentials, scope=customer and no vas" do
      {:error, %{ error: error }} = Authentication.get_token(%{ username: "customer1@example.com", password: "test1234", scope: "customer" }, nil)

      assert error == :invalid_request
    end

    test "with valid customer credentials, scope=customer and valid account vas", %{ account1_id: account1_id } do
      {:ok, token} = Authentication.get_token(%{ username: "customer1@example.com", password: "test1234", scope: "customer" }, %{ account_id: account1_id })

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token
    end

    test "with valid customer credentials, scope=customer and invalid account vas" do
      {:error, %{ error: error }} = Authentication.get_token(%{ username: "customer1@example.com", password: "test1234", scope: "customer" }, %{ account_id: "" })

      assert error == :invalid_client
    end

    test "with valid customer credentials, scope=customer and wrong account vas" do
      {:error, %{ error: error }} = Authentication.get_token(%{ username: "customer1@example.com", password: "test1234", scope: "customer" }, %{ account_id: "827ae785-1502-4489-8a97-609c4840168f" })

      assert error == :invalid_grant
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
      {:ok, %{ access_token: _ }} = Authentication.get_token(%{ username: "user1@example.com", password: "test1234", scope: "user" }, nil)
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
      {:ok, %{ access_token: _ }} = Authentication.get_token(%{ username: "user1@example.com", password: "test1234", scope: "user" }, nil)
      {:ok, token} = Authentication.get_token(%{ refresh_token: user1_rt }, %{ account_id: account1_id, user_id: user1_id })

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token
    end

    test "with customer refresh_token and valid customer vas", %{ account1_id: account1_id, customer1_id: customer1_id, customer1_rt: customer1_rt } do
      {:ok, token} = Authentication.get_token(%{ refresh_token: customer1_rt }, %{ account_id: account1_id, customer_id: customer1_id })

      assert token.access_token
      assert token.token_type
      assert token.expires_in
      assert token.refresh_token
    end
  end
end
