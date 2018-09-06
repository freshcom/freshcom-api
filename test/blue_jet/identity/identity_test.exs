defmodule BlueJet.Identity.IdentityTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity
  alias BlueJet.Identity.{User, Account, RefreshToken}
  alias BlueJet.Identity.ServiceMock

  #
  # MARK: Account
  #
  describe "get_account/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = Identity.get_account(request)
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: nil,
        role: "guest"
      }

      ServiceMock
      |> expect(:get_account, fn(id) ->
          assert id == account.id

          account
         end)

      {:ok, _} = Identity.get_account(request)
    end
  end

  describe "update_account/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Identity.update_account(request)
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "name" => Faker.Company.name()
        }
      }

      ServiceMock
      |> expect(:update_account, fn(account, fields, opts) ->
          assert account == account
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, account}
         end)

      {:ok, _} = Identity.update_account(request)
    end
  end

  describe "reset_account/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Identity.reset_account(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:reset_account, fn(account) ->
          assert account == account

          {:ok, account}
         end)

      {:ok, _} = Identity.reset_account(request)
    end
  end

  #
  # MARK: Account Membership
  #
  describe "list_account_membership/1" do
    test "when no params and role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "developer"
      }

      {:error, :access_denied} = Identity.list_account_membership(request)
    end

    test "when target is user and role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        params: %{"target" => "user"},
        role: "customer"
      }

      {:error, :access_denied} = Identity.list_account_membership(request)
    end

    test "when no params" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_account_membership, fn(fields, _) ->
          assert fields[:filter][:account_id] == account.id

          {:ok, nil}
         end)
      |> expect(:count_account_membership, fn(_, _) ->
          2
         end)
      |> expect(:count_account_membership, fn(_, _) ->
          2
         end)

      {:ok, _} = Identity.list_account_membership(request)
    end

    test "when target=user" do
      user = %User{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: %Account{},
        user: user,
        params: %{"target" => "user"},
        role: "developer"
      }

      ServiceMock
      |> expect(:list_account_membership, fn(fields, _) ->
          assert fields[:filter][:user_id] == user.id

          {:ok, nil}
         end)
      |> expect(:count_account_membership, fn(_, _) ->
          2
         end)
      |> expect(:count_account_membership, fn(_, _) ->
          2
         end)

      {:ok, _} = Identity.list_account_membership(request)
    end
  end

  describe "update_account_membership/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "developer"
      }

      {:error, :access_denied} = Identity.update_account_membership(request)
    end

    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{
          "role" => "developer"
        }
      }

      ServiceMock
      |> expect(:update_account_membership, fn(identifiers, fields, _) ->
          assert identifiers[:id] == request.params["id"]
          assert fields == request.fields

          {:ok, nil}
         end)

      {:ok, _} = Identity.update_account_membership(request)
    end
  end

  #
  # MARK: Email Verification Token
  #
  describe "create_email_verification_token/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, :access_denied} = Identity.create_email_verification_token(request)
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "user_id" => Ecto.UUID.generate()
        }
      }

      ServiceMock
      |> expect(:create_email_verification_token, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, nil}
         end)

      {:ok, _} = Identity.create_email_verification_token(request)
    end
  end

  #
  # MARK: Email Verification
  #
  describe "create_email_verification/1" do
    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "token" => "token"
        }
      }

      ServiceMock
      |> expect(:create_email_verification, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, nil}
         end)

      {:ok, _} = Identity.create_email_verification(request)
    end
  end

  #
  # MARK: Phone Verification Code
  #
  describe "create_phone_verification_code/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = Identity.create_phone_verification_code(request)
    end

    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: nil,
        role: "guest",
        fields: %{
          "phone_number" => Faker.Phone.EnUs.phone()
        }
      }

      ServiceMock
      |> expect(:create_phone_verification_code, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, nil}
         end)

      {:ok, _} = Identity.create_phone_verification_code(request)
    end
  end

  #
  # MARK: Password Reset Token
  #
  describe "create_password_reset_token/1" do
    test "when request is valid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "username" => Faker.Internet.safe_email()
        }
      }

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
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "username" => Faker.Internet.safe_email()
        }
      }

      ServiceMock
      |> expect(:create_password_reset_token, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, _} = Identity.create_password_reset_token(request)
    end

    test "when request is invalid" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        fields: %{
          "email" => "invalid"
        }
      }

      ServiceMock
      |> expect(:create_password_reset_token, fn(fields, opts) ->
          assert fields == request.fields
          assert opts[:account] == account

          {:error, %{ errors: "errors" }}
         end)

      {:error, _} = Identity.create_password_reset_token(request)
    end
  end

  #
  # MARK: Password
  #
  describe "update_password/1" do
    test "when request is valid" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous",
        fields: %{
          "reset_token" => "token",
          "value" => "test1234"
        }
      }

      ServiceMock
      |> expect(:update_password, fn(identifiers, new_password, _) ->
          assert identifiers[:reset_token] == request.fields["reset_token"]
          assert new_password == request.fields["value"]

          {:ok, nil}
         end)

      {:ok, _} = Identity.update_password(request)
    end

    test "when request is invalid" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous",
        fields: %{
          "reset_token" => "invalid",
          "value" => "test1234"
        }
      }

      ServiceMock
      |> expect(:update_password, fn(identifiers, new_password, _) ->
          assert identifiers[:reset_token] == request.fields["reset_token"]
          assert new_password == request.fields["value"]

          {:error, %{ errors: "errors" }}
         end)

      {:error, _} = Identity.update_password(request)
    end
  end

  #
  # MARK: Refresh Token
  #
  describe "get_refresh_token/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Identity.get_refresh_token(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:get_refresh_token, fn(opts) ->
          assert opts[:account] == account

          %RefreshToken{}
         end)

      {:ok, _} = Identity.get_refresh_token(request)
    end
  end

  #
  # MARK: User
  #
  describe "create_user/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Identity.create_user(request)
    end

    test "when role is anonymous" do
      request = %ContextRequest{
        account: nil,
        user: nil,
        role: "anonymous",
        fields: %{
          "name" => Faker.Name.name()
        }
      }

      ServiceMock
      |> expect(:create_user, fn(fields, _) ->
          assert fields["name"] == request.fields["name"]

          {:ok, %User{}}
         end)

      {:ok, _} = Identity.create_user(request)
    end

    test "when role is guest" do
      account = %Account{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: nil,
        role: "guest",
        fields: %{
          "name" => Faker.Name.name()
        }
      }

      ServiceMock
      |> expect(:create_user, fn(fields, opts) ->
          assert fields["role"] == "customer"
          assert fields["name"] == request.fields["name"]
          assert opts[:account] == account

          {:ok, %User{}}
         end)

      {:ok, _} = Identity.create_user(request)
    end
  end

  describe "get_user/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, :access_denied} = Identity.get_user(request)
    end

    test "when role is customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:get_user, fn(identifiers, opts) ->
          assert identifiers[:id] == user.id
          assert opts[:account] == account

          %User{}
         end)

      {:ok, _} = Identity.get_user(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:get_user, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          %User{}
         end)

      {:ok, _} = Identity.get_user(request)
    end
  end

  describe "update_user/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, :access_denied} = Identity.update_user(request)
    end

    test "when role is customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: account,
        user: user,
        role: "customer",
        params: %{ "id" => user.id },
        fields: %{
          "name" => Faker.Name.name()
        }
      }

      ServiceMock
      |> expect(:update_user, fn(identifiers, fields, opts) ->
          assert identifiers[:id] == user.id
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %User{}}
         end)

      {:ok, _} = Identity.update_user(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{
          "name" => Faker.Name.name()
        }
      }

      ServiceMock
      |> expect(:update_user, fn(identifiers, fields, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %User{}}
         end)

      {:ok, _} = Identity.update_user(request)
    end
  end

  describe "delete_user/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Identity.delete_user(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %ContextRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:delete_user, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert opts[:account] == account

          {:ok, nil}
         end)

      {:ok, _} = Identity.delete_user(request)
    end
  end
end
