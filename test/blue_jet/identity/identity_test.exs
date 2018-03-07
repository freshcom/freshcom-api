defmodule BlueJet.Identity.IdentityTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity
  alias BlueJet.Identity.{User, Account, AccountMembership, RefreshToken}
  alias BlueJet.Identity.ServiceMock

  # describe "list_account/1" do
  #   test "when role is not authorized" do
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

  #     {:error, error} = Identity.list_account(%AccessRequest{})

  #     assert error == :access_denied
  #   end

  #   test "when request is valid" do
  #     request = %AccessRequest{
  #       vas: %{ user_id: user.id },
  #       role: "developer",
  #       account: account
  #     }
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

  #     {:ok, response} = Identity.list_account(request)

  #     assert length(response.data) == 1
  #   end
  # end

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

  # describe "create_user/1" do
  #   test "when using anonymous identity" do
  #     request = %AccessRequest{
  #       role: "anonymous",
  #       fields: %{
  #         "username" => Faker.String.base64(5),
  #         "password" => "test1234",
  #         "account_name" => Faker.Company.name()
  #       }
  #     }

  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

  #     EventHandlerMock
  #     |> expect(:handle_event, fn(name, _) ->
  #         assert name == "identity.account.create.success"
  #         {:ok, nil}
  #        end)
  #     |> expect(:handle_event, fn(name, _) ->
  #         assert name == "identity.user.create.success"
  #         {:ok, nil}
  #        end)
  #     |> expect(:handle_event, fn(name, _) ->
  #         assert name == "identity.email_verification_token.create.success"
  #         {:ok, nil}
  #        end)

  #     {:ok, %{ data: user }} = Identity.create_user(request)
  #     user =
  #       User
  #       |> Repo.get!(user.id)
  #       |> Repo.preload([:refresh_tokens, :account_memberships])

  #     assert user.account_id == nil
  #     assert user.default_account_id != nil
  #     assert length(user.refresh_tokens) == 2
  #     assert length(user.account_memberships) == 1
  #     assert Enum.at(user.account_memberships, 0).role == "administrator"
  #   end

  #   test "when using guest identity" do
  #     account = Repo.insert!(%Account{})
  #     request = %AccessRequest{
  #       account: account,
  #       role: "guest",
  #       fields: %{
  #         "username" => Faker.String.base64(5),
  #         "password" => "test1234"
  #       }
  #     }

  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

  #     EventHandlerMock
  #     |> expect(:handle_event, fn(name, _) ->
  #         assert name == "identity.user.create.success"
  #         {:ok, nil}
  #        end)
  #     |> expect(:handle_event, fn(name, _) ->
  #         assert name == "identity.email_verification_token.create.success"
  #         {:ok, nil}
  #        end)

  #     {:ok, %{ data: user }} = Identity.create_user(request)
  #     user =
  #       User
  #       |> Repo.get!(user.id)
  #       |> Repo.preload([:refresh_tokens, :account_memberships])

  #     assert user.account_id == account.id
  #     assert user.default_account_id == account.id
  #     assert length(user.refresh_tokens) == 1
  #     assert length(user.account_memberships) == 1
  #   end
  # end

  # describe "get_user/1" do
  #   test "when role is not authorized" do
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

  #     {:error, error} = Identity.get_user(%AccessRequest{})
  #     assert error == :access_denied
  #   end

  #   test "when using customer identity" do
  #     account = Repo.insert!(%Account{})
  #     user = Repo.insert!(%User{
  #       account_id: account.id,
  #       default_account_id: account.id,
  #       username: Faker.String.base64(5)
  #     })

  #     request = %AccessRequest{
  #       account: account,
  #       role: "customer",
  #       vas: %{ user_id: user.id }
  #     }
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

  #     {:ok, response} = Identity.get_user(request)

  #     assert response.data.id == user.id
  #   end
  # end

  # describe "update_user/1" do
  #   test "when role is not authorized" do
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

  #     {:error, error} = Identity.update_user(%AccessRequest{})
  #     assert error == :access_denied
  #   end

  #   test "when using customer identity" do
  #     account = Repo.insert!(%Account{})
  #     user = Repo.insert!(%User{
  #       account_id: account.id,
  #       default_account_id: account.id,
  #       username: Faker.String.base64(5)
  #     })

  #     new_username = "username2"
  #     request = %AccessRequest{
  #       role: "customer",
  #       account: account,
  #       vas: %{ user_id: user.id },
  #       fields: %{
  #         "username" => new_username
  #       }
  #     }
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

  #     {:ok, response} = Identity.update_user(request)
  #     updated_user = Repo.get!(User, user.id)

  #     assert updated_user.username == new_username
  #     assert response.data.id == updated_user.id
  #     assert response.data.username == new_username
  #   end
  # end

  # describe "delete_user/1" do
  #   test "when role is not authorized" do
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

  #     {:error, error} = Identity.delete_user(%AccessRequest{ params: %{ "id" => Ecto.UUID.generate() }})
  #     assert error == :access_denied
  #   end

  #   test "when using customer identity deleting self" do
  #     account = Repo.insert!(%Account{})
  #     user = Repo.insert!(%User{
  #       account_id: account.id,
  #       default_account_id: account.id,
  #       username: Faker.String.base64(5)
  #     })

  #     request = %AccessRequest{
  #       account: account,
  #       role: "customer",
  #       vas: %{ user_id: user.id },
  #       params: %{ "id" => user.id }
  #     }
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

  #     {:ok, response} = Identity.delete_user(request)
  #     deleted_user = Repo.get(User, user.id)

  #     refute deleted_user
  #     assert response.data == %{}
  #   end

  #   test "when using administrator identity deleting global user" do
  #     account = Repo.insert!(%Account{})
  #     user = Repo.insert!(%User{
  #       default_account_id: account.id,
  #       username: Faker.String.base64(5)
  #     })

  #     request = %AccessRequest{
  #       account: account,
  #       role: "administrator",
  #       params: %{ "id" => user.id }
  #     }
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

  #     {:error, error} = Identity.delete_user(request)

  #     assert error == :not_found
  #   end

  #   test "when using administrator identity deleting account user" do
  #     account = Repo.insert!(%Account{})
  #     user = Repo.insert!(%User{
  #       account_id: account.id,
  #       default_account_id: account.id,
  #       username: Faker.String.base64(5)
  #     })

  #     request = %AccessRequest{
  #       account: account,
  #       role: "administrator",
  #       params: %{ "id" => user.id }
  #     }
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

  #     {:ok, _} = Identity.delete_user(request)
  #   end
  # end

  # describe "get_refresh_token/1" do
  #   test "when role is not authorized" do
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

  #     {:error, error} = Identity.delete_user(%AccessRequest{ params: %{ "id" => Ecto.UUID.generate() }})
  #     assert error == :access_denied
  #   end

  #   test "when using developer identity" do
  #     account = Repo.insert!(%Account{})
  #     prt = Repo.insert!(%RefreshToken{
  #       account_id: account.id
  #     })

  #     request = %AccessRequest{
  #       role: "developer",
  #       account: account
  #     }
  #     AuthorizationMock
  #     |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

  #     {:ok, response} = Identity.get_refresh_token(request)

  #     assert response.data.id == prt.id
  #     assert response.data.prefixed_id == RefreshToken.get_prefixed_id(prt)
  #   end
  # end
end
