defmodule BlueJet.IdentityTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity
  alias BlueJet.Identity.Service

  def get_account_membership(user, account) do
    Service.get_account_membership(%{user_id: user.id}, %{account: account})
  end

  def create_email_verification_token(managed_user) do
    expect(EventHandlerMock, :handle_event, fn(_, _) -> {:ok, nil} end)

    {:ok, managed_user} = Service.create_email_verification_token(%{"user_id" => managed_user.id}, %{account: managed_user.account})
    managed_user.email_verification_token
  end

  def create_password_reset_token(managed_user) do
    expect(EventHandlerMock, :handle_event, fn(_, _) -> {:ok, nil} end)

    {:ok, managed_user} = Service.create_password_reset_token(%{"username" => managed_user.username}, %{account: managed_user.account})
    managed_user.password_reset_token
  end

  #
  # MARK: Account
  #
  describe "get_account/1" do
    test "when role is not authorized" do
      request = %ContextRequest{}

      {:error, :access_denied} = Identity.get_account(request)
    end

    test "when request is valid" do
      account = account_fixture()
      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: nil}
      }

      {:ok, _} = Identity.get_account(request)
    end
  end

  describe "update_account/1" do
    test "when role is not authorized" do
      account = account_fixture()
      user = managed_user_fixture(account, %{role: "customer"})

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: user.id}
      }

      {:error, :access_denied} = Identity.update_account(request)
    end

    test "when request is invalid" do
      account = account_fixture()
      user = managed_user_fixture(account)

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: user.id},
        fields: %{
          "name" => ""
        }
      }

      {:error, %{errors: errors}} = Identity.update_account(request)
      assert match_keys(errors, [:name])
    end

    test "when request is valid" do
      account = account_fixture()
      user = managed_user_fixture(account)

      new_name = Faker.Company.name()
      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: user.id},
        fields: %{
          "name" => new_name
        }
      }

      {:ok, response} = Identity.update_account(request)
      assert response.data.name == new_name
    end
  end

  describe "reset_account/1" do
    test "when role is not authorized" do
      account = account_fixture()
      user = managed_user_fixture(account, %{role: "customer"})

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: user.id}
      }

      {:error, :access_denied} = Identity.reset_account(request)
    end

    test "when request is for live account" do
      account = account_fixture()
      user = managed_user_fixture(account)

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: user.id}
      }

      {:error, :unprocessable_for_live_account} = Identity.reset_account(request)
    end

    test "when request is valid" do
      account = account_fixture()
      user = managed_user_fixture(account)

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:account.reset.success"
        assert data.account.id == account.test_account_id

        {:ok, nil}
      end)

      request = %ContextRequest{
        vas: %{account_id: account.test_account_id, user_id: user.id}
      }

      {:ok, _} = Identity.reset_account(request)
    end
  end

  #
  # MARK: User
  #
  describe "create_user/1" do
    test "when role is not authorized" do
      account = account_fixture()
      user = managed_user_fixture(account, %{role: "customer"})

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: user.id}
      }

      {:error, :access_denied} = Identity.create_user(request)
    end

    test "when role is anonymous" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil},
        fields: %{
          "name" => Faker.Name.name(),
          "email" => Faker.Internet.safe_email(),
          "username" => Faker.Internet.safe_email(),
          "password" => "test1234"
        }
      }

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:account.create.success"
        assert match_keys(data, [:account])

        {:ok, nil}
      end)
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:user.create.success"
        assert match_keys(data, [:user, :account])

        {:ok, nil}
      end)
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:email_verification_token.create.success"
        assert match_keys(data, [:user])

        {:ok, nil}
      end)

      {:ok, response} = Identity.create_user(request)

      assert response.data.name == request.fields["name"]
      assert response.data.email == request.fields["email"]
      assert response.data.username == request.fields["username"]
    end

    test "when role is guest" do
      account = account_fixture()
      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: nil},
        fields: %{
          "name" => Faker.Name.name(),
          "email" => Faker.Internet.safe_email(),
          "username" => Faker.Internet.user_name(),
          "password" => "test1234"
        }
      }

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:user.create.success"
        assert match_keys(data, [:user, :account])

        {:ok, nil}
      end)
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:email_verification_token.create.success"
        assert match_keys(data, [:user])

        {:ok, nil}
      end)

      {:ok, response} = Identity.create_user(request)

      assert response.data.name == request.fields["name"]
      assert response.data.email == request.fields["email"]
      assert response.data.username == request.fields["username"]
    end
  end

  describe "get_user/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Identity.get_user(request)
    end

    test "when role is customer" do
      account = account_fixture()
      user = managed_user_fixture(account, %{role: "customer"})

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: user.id}
      }

      {:ok, response} = Identity.get_user(request)

      assert response.data.id == user.id
    end

    test "when role is administrator" do
      user = standard_user_fixture()
      managed_user = managed_user_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{"id" => managed_user.id}
      }

      {:ok, response} = Identity.get_user(request)

      assert response.data.id == managed_user.id
    end
  end

  describe "update_user/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Identity.update_user(request)
    end

    test "when role is customer" do
      account = account_fixture()
      user = managed_user_fixture(account, %{role: "customer"})

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: user.id},
        fields: %{"name" => Faker.Name.name()}
      }

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:user.update.success"
        assert match_keys(data, [:changeset, :account])

        {:ok, nil}
      end)

      {:ok, response} = Identity.update_user(request)

      assert response.data.id == user.id
      assert response.data.name == request.fields["name"]
    end

    test "when role is administrator" do
      user = standard_user_fixture()
      managed_user = managed_user_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{"id" => managed_user.id},
        fields: %{"name" => Faker.Name.name()}
      }

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:user.update.success"
        assert match_keys(data, [:changeset, :account])

        {:ok, nil}
      end)

      {:ok, response} = Identity.update_user(request)

      assert response.data.id == managed_user.id
      assert response.data.name == request.fields["name"]
    end
  end

  describe "delete_user/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Identity.delete_user(request)
    end

    test "when role is administrator" do
      user = standard_user_fixture()
      managed_user = managed_user_fixture(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{"id" => managed_user.id}
      }

      {:ok, _} = Identity.delete_user(request)
    end
  end

  #
  # MARK: Account Membership
  #
  describe "list_account_membership/1" do
    test "when no params and role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Identity.list_account_membership(request)
    end

    test "when no params" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id}
      }

      {:ok, response} = Identity.list_account_membership(request)

      assert length(response.data) == 1
    end

    test "when target=user" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        params: %{"target" => "user"}
      }

      {:ok, response} = Identity.list_account_membership(request)

      assert length(response.data) == 1
    end
  end

  describe "update_account_membership/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Identity.update_account_membership(request)
    end

    test "when request is valid" do
      user = standard_user_fixture()
      account_membership =
        user.default_account
        |> managed_user_fixture()
        |> get_account_membership(user.default_account)

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id},
        identifiers: %{"id" => account_membership.id},
        fields: %{"role" => "developer"}
      }

      {:ok, response} = Identity.update_account_membership(request)

      assert response.data.role == request.fields["role"]
    end
  end

  #
  # MARK: Email Verification Token
  #
  describe "create_email_verification_token/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Identity.create_email_verification_token(request)
    end

    test "when request is valid" do
      user = standard_user_fixture()

      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id}
      }

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:email_verification_token.create.success"
        assert match_keys(data, [:user])

        {:ok, nil}
      end)

      {:ok, response} = Identity.create_email_verification_token(request)

      assert response.data.id == user.id
      assert response.data.email_verification_token
    end
  end

  #
  # MARK: Email Verification
  #
  describe "create_email_verification/1" do
    test "when token is invalid" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil},
        fields: %{
          "token" => "invalid"
        }
      }

      {:error, %{errors: errors}} = Identity.create_email_verification(request)

      assert match_keys(errors, [:token])
    end

    test "when token is valid" do
      account = account_fixture()
      managed_user = managed_user_fixture(account)
      token = create_email_verification_token(managed_user)

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: nil},
        fields: %{
          "token" => token
        }
      }

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:email.verify.success"
        assert match_keys(data, [:user])

        {:ok, nil}
      end)

      {:ok, response} = Identity.create_email_verification(request)

      assert response.data.email_verified
    end
  end

  #
  # MARK: Phone Verification Code
  #
  describe "create_phone_verification_code/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Identity.create_phone_verification_code(request)
    end

    test "when request is valid" do
      account = account_fixture()

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: nil},
        fields: %{"phone_number" => "+1234567890"}
      }

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:phone_verification_code.create.success"
        assert match_keys(data, [:phone_verification_code])

        {:ok, nil}
      end)

      {:ok, _} = Identity.create_phone_verification_code(request)
    end
  end

  #
  # MARK: Password Reset Token
  #
  describe "create_password_reset_token/1" do
    test "when given username is not found" do
      account = account_fixture()
      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: nil},
        fields: %{"username" => Faker.Internet.safe_email()}
      }

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:password_reset_token.create.error.username_not_found"
        assert match_keys(data, [:username, :account])

        {:ok, nil}
      end)

      {:error, %{errors: errors}} = Identity.create_password_reset_token(request)

      assert match_keys(errors, [:username])
    end

    test "when request is valid" do
      account = account_fixture()
      managed_user = managed_user_fixture(account)

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: nil},
        fields: %{"username" => managed_user.username}
      }

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
        assert event_name == "identity:password_reset_token.create.success"
        assert match_keys(data, [:user])

        {:ok, nil}
      end)

      {:ok, response} = Identity.create_password_reset_token(request)

      assert response.data.password_reset_token
    end
  end

  #
  # MARK: Password
  #
  describe "update_password/1" do
    test "when request is invalid" do
      account = account_fixture()

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: nil},
        identifiers: %{"reset_token" => "invalid"},
        fields: %{"value" => "test1234"}
      }

      {:error, %{errors: errors}} = Identity.update_password(request)

      assert match_keys(errors, [:reset_token])
    end

    test "when request is valid" do
      account = account_fixture()
      managed_user = managed_user_fixture(account)
      token = create_password_reset_token(managed_user)

      request = %ContextRequest{
        vas: %{account_id: account.id, user_id: nil},
        identifiers: %{"reset_token" => token},
        fields: %{"value" => "test1234"}
      }

      {:ok, response} = Identity.update_password(request)

      assert response.data.reset_token == nil
    end
  end

  #
  # MARK: Refresh Token
  #
  describe "get_refresh_token/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        vas: %{account_id: nil, user_id: nil}
      }

      {:error, :access_denied} = Identity.get_refresh_token(request)
    end

    test "when role is administrator" do
      user = standard_user_fixture()
      request = %ContextRequest{
        vas: %{account_id: user.default_account.id, user_id: user.id}
      }

      {:ok, response} = Identity.get_refresh_token(request)

      assert response.data.id
    end
  end
end
