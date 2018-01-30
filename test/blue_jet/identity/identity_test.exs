defmodule BlueJet.Identity.IdentityTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity
  alias BlueJet.Identity.{User, Account, AccountMembership, RefreshToken}

  describe "list_account/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.list_account(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        name: Faker.String.base64(5),
        username: Faker.Internet.email()
      })
      Repo.insert!(%AccountMembership{
        account_id: account.id,
        user_id: user.id,
        role: "developer"
      })

      request = %AccessRequest{
        vas: %{ user_id: user.id },
        role: "developer",
        account: account
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Identity.list_account(request)

      assert length(response.data) == 1
    end
  end

  describe "get_account/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.get_account(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      request = %AccessRequest{
        role: "developer",
        account: account
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Identity.get_account(request)

      assert response.data.id == account.id
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
      account = Repo.insert!(%Account{})
      test_account = Repo.insert!(%Account{
        mode: "test",
        live_account_id: account.id
      })
      new_name = Faker.Company.name()
      request = %AccessRequest{
        account: account,
        role: "administrator",
        fields: %{
          "name" => new_name
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Identity.update_account(request)
      updated_account = Repo.get(Account, account.id)
      updated_test_account = Repo.get(Account, test_account.id)

      assert response.data.id == account.id
      assert response.data.name == new_name
      assert updated_account.name == new_name
      assert updated_test_account.name == new_name
    end
  end

  describe "create_password_reset_token/1" do
    test "when using anonymous identity for account identity" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        username: Faker.Internet.email(),
        email: Faker.Internet.email(),
        account_id: account.id,
        default_account_id: account.id
      })

      request = %AccessRequest{
        role: "anonymous",
        fields: %{ "email" => user.email }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.password_reset_token.not_created"
          {:ok, nil}
         end)

      {:ok, response} = Identity.create_password_reset_token(request)

      updated_user = Repo.get!(User, user.id)

      refute updated_user.password_reset_token
      assert response.data == %{}
    end

    test "when using guest identity for account identity" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        username: Faker.Internet.email(),
        email: Faker.Internet.email(),
        account_id: account.id,
        default_account_id: account.id
      })

      request = %AccessRequest{
        role: "guest",
        account: account,
        fields: %{ "email" => user.email }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.password_reset_token.after_create"
          {:ok, nil}
         end)

      {:ok, response} = Identity.create_password_reset_token(request)

      updated_user = Repo.get!(User, user.id)

      assert updated_user.password_reset_token
      assert response.data == %{}
    end

    test "when using anonymous identity for global identity" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        username: Faker.Internet.email(),
        email: Faker.Internet.email(),
        default_account_id: account.id
      })

      request = %AccessRequest{
        role: "anonymous",
        fields: %{ "email" => user.email }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.password_reset_token.after_create"
          {:ok, nil}
         end)

      {:ok, response} = Identity.create_password_reset_token(request)

      updated_user = Repo.get!(User, user.id)

      assert updated_user.password_reset_token
      assert response.data == %{}
    end

    test "when using guest identity for global identity" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        username: Faker.Internet.email(),
        email: Faker.Internet.email(),
        default_account_id: account.id
      })

      request = %AccessRequest{
        role: "anonymous",
        account: account,
        fields: %{ "email" => user.email }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.password_reset_token.not_created"
          {:ok, nil}
         end)

      {:ok, response} = Identity.create_password_reset_token(request)

      updated_user = Repo.get!(User, user.id)

      refute updated_user.password_reset_token
      assert response.data == %{}
    end
  end

  describe "create_password" do
    test "when role is anonymous and using non-existing password reset token" do
      request = %AccessRequest{
        role: "anonymous",
        fields: %{
          "token" => Faker.String.base64(12),
          "value" => "test1234"
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:error, :not_found} = Identity.create_password(request)
    end

    test "when role is anonymous and using valid password reset token" do
      account = Repo.insert!(%Account{})
      password_reset_token = Ecto.UUID.generate()
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        default_account_id: account.id,
        password_reset_token: password_reset_token
      })
      request = %AccessRequest{
        role: "anonymous",
        fields: %{
          "token" => password_reset_token,
          "value" => "test1234"
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, _} = Identity.create_password(request)
      user = Repo.get(User, user.id)
      assert user.encrypted_password
    end

    test "when role is guest and using non-existing password reset token" do
      account = Repo.insert!(%Account{})
      request = %AccessRequest{
        role: "guest",
        account: account,
        fields: %{
          "token" => Faker.String.base64(12),
          "value" => "test1234"
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:error, :not_found} = Identity.create_password(request)
    end

    test "when role is guest and using valid password reset token" do
      account = Repo.insert!(%Account{})
      password_reset_token = Ecto.UUID.generate()
      user = Repo.insert!(%User{
        username: Faker.String.base64(5),
        default_account_id: account.id,
        account_id: account.id,
        password_reset_token: password_reset_token
      })
      request = %AccessRequest{
        role: "guest",
        account: account,
        fields: %{
          "token" => password_reset_token,
          "value" => "test1234"
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, _} = Identity.create_password(request)
      user = Repo.get(User, user.id)
      assert user.encrypted_password
    end
  end

  describe "create_user/1" do
    test "when using anonymous identity" do
      request = %AccessRequest{
        role: "anonymous",
        fields: %{
          "username" => Faker.String.base64(5),
          "password" => "test1234",
          "account_name" => Faker.Company.name()
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.account.after_create"
          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.user.after_create"
          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.email_confirmation_token.after_create"
          {:ok, nil}
         end)

      {:ok, %{ data: user }} = Identity.create_user(request)
      user =
        User
        |> Repo.get!(user.id)
        |> Repo.preload([:refresh_tokens, :account_memberships])

      assert user.account_id == nil
      assert user.default_account_id != nil
      assert length(user.refresh_tokens) == 2
      assert length(user.account_memberships) == 1
      assert Enum.at(user.account_memberships, 0).role == "administrator"
    end

    test "when using guest identity" do
      account = Repo.insert!(%Account{})
      request = %AccessRequest{
        account: account,
        role: "guest",
        fields: %{
          "username" => Faker.String.base64(5),
          "password" => "test1234"
        }
      }

      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      EventHandlerMock
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.user.after_create"
          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, _) ->
          assert name == "identity.email_confirmation_token.after_create"
          {:ok, nil}
         end)

      {:ok, %{ data: user }} = Identity.create_user(request)
      user =
        User
        |> Repo.get!(user.id)
        |> Repo.preload([:refresh_tokens, :account_memberships])

      assert user.account_id == account.id
      assert user.default_account_id == account.id
      assert length(user.refresh_tokens) == 1
      assert length(user.account_memberships) == 1
    end
  end

  describe "get_user/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.get_user(%AccessRequest{})
      assert error == :access_denied
    end

    test "when using customer identity" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })

      request = %AccessRequest{
        account: account,
        role: "customer",
        vas: %{ user_id: user.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Identity.get_user(request)

      assert response.data.id == user.id
    end
  end

  describe "update_user/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.update_user(%AccessRequest{})
      assert error == :access_denied
    end

    test "when using customer identity" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })

      new_username = Faker.String.base64(5)
      request = %AccessRequest{
        role: "customer",
        account: account,
        vas: %{ user_id: user.id },
        fields: %{
          "username" => new_username
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Identity.update_user(request)
      updated_user = Repo.get!(User, user.id)

      assert updated_user.username == new_username
      assert response.data.id == updated_user.id
      assert response.data.username == new_username
    end
  end

  describe "delete_user/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.delete_user(%AccessRequest{ params: %{ "id" => Ecto.UUID.generate() }})
      assert error == :access_denied
    end

    test "when using customer identity deleting self" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })

      request = %AccessRequest{
        account: account,
        role: "customer",
        vas: %{ user_id: user.id },
        params: %{ "id" => user.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Identity.delete_user(request)
      deleted_user = Repo.get(User, user.id)

      refute deleted_user
      assert response.data == %{}
    end

    test "when using administrator identity deleting global user" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })

      request = %AccessRequest{
        account: account,
        role: "administrator",
        params: %{ "id" => user.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:error, error} = Identity.delete_user(request)

      assert error == :not_found
    end

    test "when using administrator identity deleting account user" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.String.base64(5)
      })

      request = %AccessRequest{
        account: account,
        role: "administrator",
        params: %{ "id" => user.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, _} = Identity.delete_user(request)
    end
  end

  describe "get_refresh_token/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Identity.delete_user(%AccessRequest{ params: %{ "id" => Ecto.UUID.generate() }})
      assert error == :access_denied
    end

    test "when using developer identity" do
      account = Repo.insert!(%Account{})
      prt = Repo.insert!(%RefreshToken{
        account_id: account.id
      })

      request = %AccessRequest{
        role: "developer",
        account: account
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Identity.get_refresh_token(request)

      assert response.data.id == prt.id
      assert response.data.prefixed_id == RefreshToken.get_prefixed_id(prt)
    end
  end
end
