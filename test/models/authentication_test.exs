defmodule BlueJet.AuthenticationTest do
  use BlueJet.ModelCase

  alias BlueJet.Authentication
  alias BlueJet.Registration

  describe "get_jwt/1" do
    test "with valid credentials" do
      Registration.sign_up(%{ first_name: "Roy", last_name: "Bao", password: "test1234", email: "test1@example.com", account_name: "Outersky" })
      {:ok, jwt} = Authentication.get_jwt(%{ email: "test1@example.com", password: "test1234" })

      assert jwt.value
    end

    test "with missing credentials" do
      {:error, _} = Authentication.get_jwt(%{ password: "test1234" })
    end

    test "with invalid credentials" do
      {:error, _} = Authentication.get_jwt(%{ email: "test1@example.com", password: "test1234" })
    end
  end
end
