defmodule BlueJet.AuthenticationTest do
  use BlueJet.ModelCase

  alias BlueJet.Authentication
  alias BlueJet.Registration

  setup do
    {_, user} = Registration.sign_up(%{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      email: "test1@example.com",
      password: "test1234",
      account_name: Faker.Company.name()
    })

    %{ user: user }
  end

  describe "get_jwt/1" do
    test "with valid credentials" do
      {:ok, jwt} = Authentication.get_jwt(%{ email: "test1@example.com", password: "test1234" })

      assert jwt.value
    end

    test "with missing credentials" do
      {:error, _} = Authentication.get_jwt(%{ password: "test1234" })
    end

    test "with invalid credentials" do
      {:error, _} = Authentication.get_jwt(%{ email: "invalid", password: "invalid" })
    end
  end
end
