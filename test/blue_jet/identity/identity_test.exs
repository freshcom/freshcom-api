defmodule BlueJet.Identity.IdentityTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity
  alias BlueJet.Identity.{User, Account, RefreshToken}
  alias BlueJet.Identity.ServiceMock

  describe "get_account/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.get_account(%AccessRequest{})

      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
        end)

      ServiceMock
      |> expect(:get_account, fn(id) ->
          assert id == account.id

          {:ok, account}
         end)

      {:ok, response} = Identity.get_account(request)

      assert response.data == account
    end
  end

  describe "update_account/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.update_account(%AccessRequest{})

      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      new_name = Faker.Company.name()
      request = %AccessRequest{
        account: account,
        fields: %{
          "name" => new_name
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_account, fn(account, fields, opts) ->
          assert account == account
          assert fields == request.fields
          assert opts[:account] == account

          account = %{ account | name: new_name }
          {:ok, account}
         end)

      {:ok, response} = Identity.update_account(request)

      assert response.data.id == account.id
      assert response.data.name == new_name
    end

    test "when request is invalid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "name" => nil
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_account, fn(account, fields, opts) ->
          assert account == account
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Identity.update_account(request)

      assert response.errors == "errors"
    end
  end

  describe "create_email_verification_token/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.create_email_verification_token(%AccessRequest{})

      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "email" => Faker.Internet.safe_email()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_email_verification_token, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, nil}
         end)

      {:ok, _} = Identity.create_email_verification_token(request)
    end

    test "when request is invalid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "email" => "invalid"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_email_verification_token, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Identity.create_email_verification_token(request)

      assert response.errors == "errors"
    end
  end

  describe "create_email_verification/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.create_email_verification(%AccessRequest{})

      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "token" => "token"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_email_verification, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, nil}
         end)

      {:ok, _} = Identity.create_email_verification(request)
    end

    test "when request is invalid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "token" => "invalid"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_email_verification, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Identity.create_email_verification(request)

      assert response.errors == "errors"
    end
  end

  describe "create_phone_verification_code/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.create_phone_verification_code(%AccessRequest{})

      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "phone_number" => Faker.Phone.EnUs.phone()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_phone_verification_code, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, nil}
         end)

      {:ok, _} = Identity.create_phone_verification_code(request)
    end

    test "when request is invalid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "phone_number" => "invalid"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_phone_verification_code, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Identity.create_phone_verification_code(request)

      assert response.errors == "errors"
    end
  end

  describe "create_password_reset_token/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.create_password_reset_token(%AccessRequest{})

      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "email" => Faker.Internet.safe_email()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_password_reset_token, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, nil}
         end)

      {:ok, _} = Identity.create_password_reset_token(request)
    end

    test "when request is valid but no user for the email is found" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "email" => Faker.Internet.safe_email()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_password_reset_token, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:error, :not_found}
         end)

      {:ok, _} = Identity.create_password_reset_token(request)
    end

    test "when request is invalid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "email" => "invalid"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_password_reset_token, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Identity.create_password_reset_token(request)

      assert response.errors == "errors"
    end
  end

  describe "update_password/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.update_password(%AccessRequest{})

      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "reset_token" => "token",
          "value" => "test1234"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_password, fn(identifiers, new_password, opts) ->
          assert identifiers["reset_token"] == request.fields["reset_token"]
          assert new_password == request.fields["value"]
          assert opts[:account] == account

          {:ok, nil}
         end)

      {:ok, _} = Identity.update_password(request)
    end

    test "when request is invalid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "reset_token" => "invalid",
          "value" => "test1234"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_password, fn(identifiers, new_password, opts) ->
          assert identifiers["reset_token"] == request.fields["reset_token"]
          assert new_password == request.fields["value"]
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Identity.update_password(request)

      assert response.errors == "errors"
    end
  end

  describe "create_user/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.create_user(%AccessRequest{})

      assert error == :access_denied
    end

    test "when role is guest and request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      user = %User{}
      request = %AccessRequest{
        account: account,
        role: "guest",
        fields: %{
          "name" => Faker.Name.name()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_user, fn(fields, opts) ->
          assert fields["role"] == "customer"
          assert fields["name"] == request.fields["name"]
          assert opts[:account] == account

          {:ok, user}
         end)

      {:ok, _} = Identity.create_user(request)
    end

    test "when role is anonymous and request is valid" do
      account = %Account{}
      user = %User{ default_account: account }
      request = %AccessRequest{
        role: "anonymous",
        fields: %{
          "name" => Faker.Name.name()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_user, fn(fields, _) ->
          assert fields["name"] == request.fields["name"]

          {:ok, user}
         end)

      {:ok, _} = Identity.create_user(request)
    end

    test "when request is invalid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        fields: %{
          "username" => "invalid"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:create_user, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Identity.create_user(request)

      assert response.errors == "errors"
    end
  end

  describe "get_user/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.get_user(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        vas: %{ user_id: Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:get_user, fn(identifiers, opts) ->
          assert identifiers["id"] == request.vas[:user_id]
          assert opts[:account] == account

          {:ok, %User{}}
         end)

      {:ok, _} = Identity.get_user(request)
    end
  end

  describe "update_user/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.update_user(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        vas: %{ user_id: Ecto.UUID.generate() },
        fields: %{
          "name" => Faker.Name.name()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_user, fn(id, fields, opts) ->
          assert id == request.vas[:user_id]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %User{}}
         end)

      {:ok, _} = Identity.update_user(request)
    end

    test "when request is invalid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        vas: %{ user_id: Ecto.UUID.generate() },
        fields: %{
          "name" => "invalid"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:update_user, fn(id, fields, opts) ->
          assert id == request.vas[:user_id]
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, response} = Identity.update_user(request)

      assert response.errors == "errors"
    end
  end

  describe "delete_user/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.delete_user(%AccessRequest{ params: %{ "id" => Ecto.UUID.generate() } })
      assert error == :access_denied
    end

    test "when request is denied" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        role: "customer",
        vas: %{ user_id: Ecto.UUID.generate() },
        params: %{ "id" => Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      {:error, :access_denied} = Identity.delete_user(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        vas: %{ user_id: Ecto.UUID.generate() },
        params: %{ "id" => Ecto.UUID.generate() }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:delete_user, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, nil}
         end)

      {:ok, _} = Identity.delete_user(request)
    end
  end

  describe "get_refresh_token/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.get_refresh_token(%AccessRequest{ params: %{ "id" => Ecto.UUID.generate() }})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) ->
          {:ok, request}
         end)

      ServiceMock
      |> expect(:get_refresh_token, fn(opts) ->
          assert opts[:account] == account

          %RefreshToken{}
         end)

      {:ok, _} = Identity.get_refresh_token(request)
    end
  end
end
