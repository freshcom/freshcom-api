defmodule BlueJet.Identity.ServiceTest do
  use BlueJet.DataCase

  import BlueJet.Identity.TestHelper

  alias BlueJet.Identity.Service
  alias BlueJet.Identity.{User, Account, AccountMembership, RefreshToken}

  def refresh_tfa_code(user) do
    Service.refresh_tfa_code(user)
  end

  #
  # MARK: Authentication
  #
  describe "create_access_token/1" do
    test "when using incorrect credentials and no scope" do
      {:error, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => "invalid",
        "password" => "invalid"
      })

      assert result.error == :invalid_grant
      assert result.error_description
    end

    test "when using standard user credentials and scope" do
      user = standard_user_fixture()

      {:error, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "account_id:#{user.default_account.id}"
      })

      # When scope is provided, we should only create token for managed user
      assert result.error == :invalid_grant
      assert result.error_description
    end

    test "when using standard user credentials and no scope" do
      user = standard_user_fixture()

      {:ok, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end

    test "when using managed user credentials and no scope" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      {:error, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "test1234"
      })

      assert result.error == :invalid_grant
      assert result.error_description
    end

    test "when using managed user credentials and invalid scope" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      {:error, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "test1234",
        "scope" => "aid:#{UUID.generate()}"
      })

      assert result.error == :invalid_grant
      assert result.error_description
    end

    test "when using managed user credentials and valid scope" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      {:ok, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => managed_user.username,
        "password" => "test1234",
        "scope" => "aid:#{managed_user.account_id}"
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end

    test "when using incorrect refresh token" do
      {:error, result} = Service.create_access_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => UUID.generate()
      })

      assert result.error == :invalid_grant
      assert result.error_description
    end

    test "when using prt and no scope" do
      account = account_fixture()
      prt = get_prt(account)

      {:ok, result} = Service.create_access_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => prt
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end

    test "when using urt and no scope" do
      user = standard_user_fixture()
      urt = get_urt(user.default_account, user)
      {:ok, result} = Service.create_access_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => urt
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end

    test "when using urt and scope containing test account id" do
      user = standard_user_fixture()
      urt = get_urt(user.default_account, user)
      test_account = user.default_account.test_account
      urt_test = get_urt(test_account, user)

      {:ok, result} = Service.create_access_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => urt,
        "scope" => "account_id:#{test_account.id}"
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token == urt_test
      assert result.token_type
    end

    test "when standard user auth method is tfa_sms and no otp" do
      user = standard_user_fixture(%{
        auth_method: "tfa_sms",
        phone_number: "+1234567890"
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.tfa_code.create.success"
          assert data[:user].tfa_code

          {:ok, nil}
         end)

      {:error, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234"
      })

      assert result.error == :invalid_otp
      assert result.error_description
    end

    test "when standard user auth method is tfa_sms and invalid otp" do
      user =
        %{auth_method: "tfa_sms", phone_number: "+1234567890"}
        |> standard_user_fixture()
        |> refresh_tfa_code()

      {:error, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "otp" => "invalid"
      })

      assert result.error == :invalid_otp
      assert result.error_description
    end

    test "when standard user auth method is tfa_sms and valid otp" do
      user =
        %{auth_method: "tfa_sms", phone_number: "+1234567890"}
        |> standard_user_fixture()
        |> refresh_tfa_code()

      {:ok, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "otp" => user.tfa_code
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end

    test "when managed user auth method is tfa_sms and no otp" do
      standard_user = standard_user_fixture()
      user = managed_user_fixture(standard_user.default_account, %{
        auth_method: "tfa_sms",
        phone_number: "+1234567890"
      })

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.tfa_code.create.success"
          assert data[:user].tfa_code

          {:ok, nil}
         end)

      {:error, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{standard_user.default_account.id}"
      })

      assert result.error == :invalid_otp
      assert result.error_description
    end

    test "when managed user auth method is tfa_sms and invalid otp" do
      standard_user = standard_user_fixture()
      user =
        standard_user.default_account
        |> managed_user_fixture(%{auth_method: "tfa_sms", phone_number: "+1234567890"})
        |> refresh_tfa_code()

      {:error, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{standard_user.default_account.id}",
        "otp" => "invalid"
      })

      assert result.error == :invalid_otp
      assert result.error_description
    end

    test "when managed user auth method is tfa_sms and valid otp" do
      standard_user = standard_user_fixture()
      user =
        standard_user.default_account
        |> managed_user_fixture(%{auth_method: "tfa_sms", phone_number: "+1234567890"})
        |> refresh_tfa_code()

      {:ok, result} = Service.create_access_token(%{
        "grant_type" => "password",
        "username" => user.username,
        "password" => "test1234",
        "scope" => "aid:#{standard_user.default_account.id}",
        "otp" => user.tfa_code
      })

      assert result.expires_in
      assert result.access_token
      assert result.refresh_token
      assert result.token_type
    end
  end

  #
  # MARK: Account
  #
  describe "get_account/1" do
    test "when only account_id is given" do
      account = Repo.insert!(%Account{})

      assert Service.get_account(%{ account_id: nil }) == nil
      assert Service.get_account(%{ account_id: account.id }).id == account.id
    end

    test "when only account is given" do
      account = Repo.insert!(%Account{})

      assert Service.get_account(%{ account: nil }) == nil
      assert Service.get_account(%{ account: account }) == account
    end

    test "when both account and account_id is given but account is nil" do
      account = Repo.insert!(%Account{})

      assert Service.get_account(%{ account_id: account.id, account: nil }).id == account.id
    end

    test "when both account and account_id is given and account is not nil" do
      account = Repo.insert!(%Account{})

      assert Service.get_account(%{ account_id: account.id, account: account }) == account
    end
  end

  describe "create_account/1" do
    test "when fields are invalid" do
      {:error, changeset} = Service.create_account(%{})

      assert changeset.valid? == false
    end

    test "when fields are valid and no user given" do
      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity:account.create.success"
          assert Map.keys(data) == [:account]

          {:ok, nil}
         end)

      fields = %{"name" => Faker.Company.name()}

      {:ok, account} = Service.create_account(fields)
      test_account = account.test_account

      assert account.mode == "live"
      assert test_account.mode == "test"
      assert Repo.get_by(RefreshToken, account_id: account.id)
      assert Repo.get_by(RefreshToken, account_id: test_account.id)
    end

    test "when managed user is given" do
      assert_raise ArgumentError, fn ->
        Service.create_account(%{}, %{user: %User{account_id: UUID.generate()}})
      end
    end

    test "when fields are valid and no standard user given" do
      standard_user = standard_user_fixture()

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity:account.create.success"
          assert Map.keys(data) == [:account]

          {:ok, nil}
         end)

      fields = %{"name" => Faker.Company.name()}
      opts = %{user: standard_user}

      {:ok, account} = Service.create_account(fields, opts)
      test_account = account.test_account

      prt_live = Repo.get_by(RefreshToken, account_id: account.id)
      prt_test = Repo.get_by(RefreshToken, account_id: test_account.id)
      membership = Repo.get_by(AccountMembership,
        account_id: account.id,
        user_id: standard_user.id,
        is_owner: true,
        role: "administrator"
      )

      assert account.mode == "live"
      assert test_account.mode == "test"
      assert prt_live
      assert prt_test
      assert membership
    end
  end

  describe "update_account/2" do
    test "when given fields are invalid" do
      account = %Account{id: UUID.generate()}
      {:error, changeset} = Service.update_account(account, %{"name" => nil})

      assert changeset.valid? == false
    end

    test "when given fields are valid" do
      account = account_fixture()

      fields = %{
        "name" => Faker.Company.name(),
        "company_name" => Faker.Company.name(),
        "default_auth_method" => "tfa_sms",
        "website_url" => Faker.Internet.url(),
        "support_email" => Faker.Internet.email(),
        "tech_email" => Faker.Internet.email(),
        "caption" => Faker.Lorem.sentence(5),
        "description" => Faker.Lorem.sentence(20)
      }

      {:ok, account} = Service.update_account(account, fields)
      test_account = account.test_account

      assert account.name == fields["name"]
      assert account.company_name == fields["company_name"]
      assert account.default_auth_method == fields["default_auth_method"]
      assert account.website_url == fields["website_url"]
      assert account.support_email == fields["support_email"]
      assert account.tech_email == fields["tech_email"]
      assert account.caption == fields["caption"]
      assert account.description == fields["description"]

      assert test_account.name == fields["name"]
      assert test_account.company_name == fields["company_name"]
      assert test_account.default_auth_method == fields["default_auth_method"]
      assert test_account.website_url == fields["website_url"]
      assert test_account.support_email == fields["support_email"]
      assert test_account.tech_email == fields["tech_email"]
      assert test_account.caption == fields["caption"]
      assert test_account.description == fields["description"]
    end
  end

  test "reset_account/1" do
    account = account_fixture().test_account

    user = Repo.insert!(%User{
      account_id: account.id,
      default_account_id: account.id,
      username: Faker.Internet.user_name()
    })
    EventHandlerMock
    |> expect(:handle_event, fn(event_name, _) ->
        assert event_name == "identity:account.reset.success"
        {:ok, nil}
       end)

    {:ok, account} = Service.reset_account(account)

    assert Repo.get(Account, account.id)
    refute Repo.get(User, user.id)
  end

  #
  # MARK: User
  #
  describe "create_user/2" do
    test "when fields given are invalid and account is nil" do
      {:error, changeset} = Service.create_user(%{}, %{account: nil})

      assert changeset.valid? == false
    end

    test "when fields given are invalid and account is valid" do
      account = %Account{id: UUID.generate()}
      {:error, changeset} = Service.create_user(%{}, %{account: account})

      assert changeset.valid? == false
    end

    test "when fields given are valid and account is nil" do
      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:account.create.success"
          assert match_keys(data, [:account])

          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.create.success"
          assert match_keys(data, [:user, :account])

          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:email_verification_token.create.success"
          assert match_keys(data, [:user])

          {:ok, nil}
         end)

      fields = %{
        "account_name" => Faker.Name.name(),
        "username" => Faker.Internet.user_name(),
        "name" => Faker.Name.name(),
        "password" => "test1234"
      }

      {:ok, user} = Service.create_user(fields, %{account: nil})

      membership = Repo.get_by(AccountMembership,
        account_id: user.default_account.id,
        user_id: user.id,
        is_owner: true,
        role: "administrator"
      )
      urt_live = Repo.get_by(RefreshToken, account_id: user.default_account.id, user_id: user.id)
      urt_test = Repo.get_by(RefreshToken, account_id: user.default_account.test_account.id, user_id: user.id)

      assert user.username == fields["username"]
      assert user.account == nil
      assert user.default_account.id
      assert membership
      assert urt_live
      assert urt_test
    end

    test "when fields given are valid and account is live account" do
      account = account_fixture()

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.create.success"
          assert match_keys(data, [:user, :account])

          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:email_verification_token.create.success"
          assert match_keys(data, [:user])

          {:ok, nil}
         end)

      fields = %{
        "username" => Faker.Internet.user_name(),
        "email" => Faker.Internet.safe_email(),
        "password" => "test1234",
        "name" => Faker.Name.name(),
        "role" => "customer"
      }

      {:ok, user} = Service.create_user(fields, %{account: account})

      account_membership = Repo.get_by(AccountMembership,
        account_id: user.default_account.id,
        user_id: user.id,
        role: fields["role"]
      )
      urt_live = Repo.get_by(RefreshToken, account_id: user.account.id, user_id: user.id)
      urt_test = Repo.get_by(RefreshToken, account_id: user.account.test_account.id, user_id: user.id)

      assert user.username == fields["username"]
      assert user.account.id == account.id
      assert user.default_account.id == account.id
      assert user.role == "customer"
      assert account_membership
      assert urt_live
      assert urt_test
    end

    test "when fields given are valid and account is test account" do
      account = account_fixture()
      test_account = account.test_account

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.create.success"
          assert match_keys(data, [:user, :account])

          {:ok, nil}
         end)
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:email_verification_token.create.success"
          assert match_keys(data, [:user])

          {:ok, nil}
         end)

      fields = %{
        "username" => Faker.Internet.user_name(),
        "email" => Faker.Internet.safe_email(),
        "password" => "test1234",
        "name" => Faker.Name.name(),
        "role" => "customer"
      }

      {:ok, user} = Service.create_user(fields, %{account: test_account})

      account_membership = Repo.get_by(AccountMembership,
        account_id: test_account.id,
        user_id: user.id,
        role: fields["role"]
      )
      urt_test = Repo.get_by(RefreshToken, account_id: test_account.id, user_id: user.id)

      assert user.username == fields["username"]
      assert user.account.id == test_account.id
      assert user.default_account.id == test_account.id
      assert user.role == "customer"
      assert account_membership
      assert urt_test
    end
  end

  describe "get_user/2" do
    test "when identifiers are for standard user and account is nil" do
      standard_user = standard_user_fixture()
      identifiers = %{id: standard_user.id}
      opts = %{account: nil}

      user = Service.get_user(identifiers, opts)

      assert user.id == standard_user.id
      assert user.role == nil
    end

    test "when identifiers are for managed user but account is nil" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      identifiers = %{id: managed_user.id}
      opts = %{account: nil}

      user = Service.get_user(identifiers, opts)

      assert user == nil
    end

    test "when identifiers are for standard user of given account but type is managed" do
      standard_user = standard_user_fixture()
      identifiers = %{id: standard_user.id}
      opts = %{type: :managed, account: standard_user.default_account}

      user = Service.get_user(identifiers, opts)

      assert user == nil
    end

    test "when identifiers are for managed user of another account and type is managed" do
      standard_user1 = standard_user_fixture()
      standard_user2 = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user2.default_account)

      identifiers = %{id: managed_user.id}
      opts = %{type: :managed, account: standard_user1.default_account}

      user = Service.get_user(identifiers, opts)

      assert user == nil
    end

    test "when identifiers are for managed user of given account and type is managed" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      identifiers = %{id: managed_user.id}
      opts = %{type: :managed, account: standard_user.default_account}

      user = Service.get_user(identifiers, opts)

      assert user.id == managed_user.id
      assert user.role == "administrator"
    end

    test "when identifiers are for managed user of another account" do
      standard_user1 = standard_user_fixture()
      standard_user2 = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user2.default_account)

      identifiers = %{id: managed_user.id}
      opts = %{account: standard_user1.default_account}

      user = Service.get_user(identifiers, opts)

      assert user == nil
    end

    test "when identifiers are for managed user of given account" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      identifiers = %{id: managed_user.id}
      opts = %{account: standard_user.default_account}

      user = Service.get_user(identifiers, opts)

      assert user.id == managed_user.id
      assert user.role == "administrator"
    end

    test "when identifiers are for standard user of another account" do
      standard_user1 = standard_user_fixture()
      standard_user2 = standard_user_fixture()

      identifiers = %{id: standard_user2.id}
      opts = %{account: standard_user1.default_account}

      user = Service.get_user(identifiers, opts)

      assert user == nil
    end

    test "when identifiers are for standard user of given account" do
      standard_user = standard_user_fixture()

      identifiers = %{id: standard_user.id}
      opts = %{account: standard_user.default_account}

      user = Service.get_user(identifiers, opts)

      assert user.id == standard_user.id
      assert user.role == "administrator"
    end
  end

  describe "update_user/3" do
    test "when user is nil" do
      {:error, :not_found} = Service.update_user(nil, %{}, %{})
    end

    test "when user is given and fields are invalid" do
      user = %User{id: UUID.generate()}
      fields = %{"name" => nil}
      opts = %{account: %Account{id: UUID.generate()}}

      {:error, changeset} = Service.update_user(user, fields, opts)

      assert changeset.valid? == false
    end

    test "when user is given and fields are valid" do
      user = standard_user_fixture()
      fields = %{"name" => Faker.Name.name()}
      opts = %{account: user.default_account}

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.update.success"
          assert match_keys(data, [:changeset, :account])

          {:ok, nil}
         end)

      {:ok, user} = Service.update_user(user, fields, opts)

      assert user.name == fields["name"]
    end

    test "when user is given and fields are valid but event handler returns error" do
      user = standard_user_fixture()
      fields = %{"email" => nil}
      opts = %{account: user.default_account}

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.update.success"
          assert match_keys(data, [:changeset, :account])

          {:error, %{errors: [email: {"can't be blank", [validation: :required]}]}}
         end)

      {:error, changeset} = Service.update_user(user, fields, opts)
      assert match_keys(changeset.errors, [:email])
    end

    test "when identifiers are given and fields are valid" do
      user = standard_user_fixture()
      account = user.default_account
      fields = %{"name" => Faker.Name.name()}

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:user.update.success"
          assert match_keys(data, [:changeset, :account])

          {:ok, nil}
         end)

      {:ok, user} = Service.update_user(%{id: user.id}, fields, %{account: account})

      assert user.name == fields["name"]
    end
  end

  describe "delete_user/2" do
    test "when identifiers are for standard user" do
      standard_user = standard_user_fixture()
      identifiers = %{id: standard_user.id}
      opts = %{account: standard_user.default_account}

      assert Service.delete_user(identifiers, opts) == {:error, :not_found}
    end

    test "when identifiers are for managed user of another account" do
      standard_user1 = standard_user_fixture()
      standard_user2 = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user2.default_account)

      identifiers = %{id: managed_user.id}
      opts = %{account: standard_user1.default_account}

      assert Service.delete_user(identifiers, opts) == {:error, :not_found}
    end

    test "when identifiers are for managed user of given account" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      identifiers = %{id: managed_user.id}
      opts = %{account: standard_user.default_account}

      {:ok, user} =  Service.delete_user(identifiers, opts)

      assert user
      assert Repo.get(User, user.id) == nil
    end
  end

  #
  # Mark: Account Membership
  #
  describe "list_account_membership/2" do
    test "when both account and user_id is not provided" do
      assert_raise ArgumentError, fn ->
        Service.list_account_membership(%{})
      end
    end

    test "when account is given" do
      standard_user_fixture()
      standard_user = standard_user_fixture()
      managed_user_fixture(standard_user.default_account)

      opts = %{account: standard_user.default_account, include: %{paths: "user"}}

      memberships = Service.list_account_membership(%{}, opts)

      assert length(memberships) == 2
      assert Enum.at(memberships, 0).user.id
    end

    test "when filter is given" do
      standard_user_fixture()
      standard_user = standard_user_fixture()
      account_fixture(standard_user)

      filter = %{user_id: standard_user.id}
      opts = %{include: %{paths: "account"}}

      memberships = Service.list_account_membership(%{filter: filter}, opts)

      assert length(memberships) == 2
      assert Enum.at(memberships, 0).account.id
    end
  end

  describe "count_account_membership/2" do
    test "when both account and user_id is not provided" do
      assert_raise ArgumentError, fn ->
        Service.count_account_membership(%{})
      end
    end

    test "when account is given" do
      standard_user_fixture()
      standard_user = standard_user_fixture()
      managed_user_fixture(standard_user.default_account)

      opts = %{account: standard_user.default_account, include: %{paths: "user"}}

      assert Service.count_account_membership(%{}, opts) == 2
    end

    test "when filter is given" do
      standard_user_fixture()
      standard_user = standard_user_fixture()
      account_fixture(standard_user)

      filter = %{user_id: standard_user.id}
      opts = %{include: %{paths: "account"}}

      assert Service.count_account_membership(%{filter: filter}, opts) == 2
    end
  end

  describe "get_account_membership/2" do
    test "when identifiers is invalid" do
      identifiers = %{id: UUID.generate()}
      opts = %{account: %Account{id: UUID.generate()}}

      assert Service.get_account_membership(identifiers, opts) == nil
    end

    test "when identifiers are valid" do
      target_membership = account_membership_fixture()

      identifiers = %{id: target_membership.id}
      opts = %{account: target_membership.account, include: %{paths: "user,account"}}

      membership = Service.get_account_membership(identifiers, opts)

      assert membership
      assert membership.user.id
      assert membership.account.id
    end
  end

  describe "update_account_membership/2" do
    test "when identifiers is invalid" do
      identifiers = %{id: UUID.generate()}
      opts = %{account: %Account{id: UUID.generate()}}

      assert Service.update_account_membership(identifiers, %{}, opts) == {:error, :not_found}
    end

    test "with given fields are invalid" do
      target_membership = account_membership_fixture(for: :managed)

      identifiers = %{id: target_membership.id}
      fields = %{"role" => "invalid"}
      opts = %{account: target_membership.account}

      {:error, changeset} = Service.update_account_membership(identifiers, fields, opts)

      assert changeset.valid? == false
      assert match_keys(changeset.errors, [:role])
    end

    test "with given fields are valid" do
      target_membership = account_membership_fixture(for: :managed)

      identifiers = %{id: target_membership.id}
      fields = %{"role" => "developer"}
      opts = %{account: target_membership.account, include: %{paths: "user,account"}}

      {:ok, membership} = Service.update_account_membership(identifiers, fields, opts)

      assert membership
      assert membership.role == "developer"
      assert membership.user
      assert membership.account
    end
  end

  #
  # MARK: Email Verification Token
  #
  describe "create_email_verification_token/2" do
    test "when user_id is nil" do
      {:error, %{errors: errors}} = Service.create_email_verification_token(%{"user_id" => nil}, %{})
      assert match_keys(errors, [:user_id])
    end

    test "user_id does not exist" do
      fields = %{"user_id" => UUID.generate()}
      opts = %{account: %Account{id: UUID.generate()}}

      {:error, %{errors: errors}} = Service.create_email_verification_token(fields, opts)
      assert match_keys(errors, [:user_id])
    end

    test "when valid user_id is given" do
      target_user = standard_user_fixture()

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:email_verification_token.create.success"
          assert match_keys(data, [:user])

          {:ok, nil}
         end)

      fields = %{"user_id" => target_user.id}
      opts = %{account: target_user.default_account}

      {:ok, user} = Service.create_email_verification_token(fields, opts)

      assert user.email_verification_token != target_user.email_verification_token
      assert user.email_verified == false
      assert user.id == target_user.id
    end
  end

  #
  # MARK: Email Verification
  #
  describe "verify_email/2" do
    test "when token is nil" do
      {:error, %{errors: errors}} = Service.verify_email(%{"token" => nil}, %{})

      assert match_keys(errors, [:token])
    end

    test "when token is invalid" do
      fields = %{"token" => UUID.generate()}
      opts = %{account: %Account{id: UUID.generate()}}

      {:error, %{errors: errors}} = Service.verify_email(fields, opts)

      assert match_keys(errors, [:token])
    end

    test "when valid token is given" do
      target_user = standard_user_fixture()

      EventHandlerMock
      |> expect(:handle_event, fn(name, data) ->
          assert name == "identity:email.verify.success"
          assert match_keys(data, [:user])

          {:ok, nil}
         end)

      fields = %{"token" => target_user.email_verification_token}
      opts = %{account: target_user.default_account}
      {:ok, user} = Service.verify_email(fields, opts)

      assert user.email_verification_token == nil
      assert user.email_verified == true
      assert user.email_verified_at
    end
  end

  #
  # MARK: Phone Verification Code
  #
  describe "create_phone_verification_code/2" do
    test "when given invalid fields" do
      opts = %{account: %Account{id: UUID.generate()}}
      {:error, changeset} = Service.create_phone_verification_code(%{}, opts)

      assert changeset.valid? == false
    end

    test "when given valid fields" do
      account = account_fixture()

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity:phone_verification_code.create.success"
          assert match_keys(data, [:phone_verification_code])

          {:ok, nil}
         end)

      fields = %{"phone_number" => "+111234567890"}
      opts = %{account: account}
      {:ok, pvc} = Service.create_phone_verification_code(fields, opts)

      assert pvc.value
    end
  end

  #
  # MARK: Password Reset Token
  #
  describe "create_password_reset_token/2" do
    test "when username is not provided" do
      {:error, %{errors: errors}} = Service.create_password_reset_token(%{"username" => ""}, %{})

      assert match_keys(errors, [:username])
    end

    test "when username is not found and account is nil" do
      EventHandlerMock
      |> expect(:handle_event, fn(event_name, _) ->
          assert event_name == "identity:password_reset_token.create.error.username_not_found"

          {:ok, nil}
         end)

      fields = %{"username" => Faker.Internet.safe_email()}
      opts = %{account: nil}

      {:error, %{errors: errors}} = Service.create_password_reset_token(fields, opts)

      assert match_keys(errors, [:username])
    end

    test "when username is not found and account is given" do
      EventHandlerMock
      |> expect(:handle_event, fn(event_name, _) ->
          assert event_name == "identity:password_reset_token.create.error.username_not_found"

          {:ok, nil}
         end)

      fields = %{"username" => Faker.Internet.safe_email()}
      opts = %{account: %Account{id: UUID.generate()}}

      {:error, %{errors: errors}} = Service.create_password_reset_token(fields, opts)

      assert match_keys(errors, [:username])
    end

    test "when username is for standard user" do
      standard_user = standard_user_fixture()

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity:password_reset_token.create.success"
          assert match_keys(data, [:user])

          {:ok, nil}
         end)

      fields = %{"username" => standard_user.username}
      opts = %{account: nil}

      {:ok, user} = Service.create_password_reset_token(fields, opts)

      assert user.password_reset_token
      assert user.password_reset_token != standard_user.password_reset_token
    end

    test "when username is for managed user of given account" do
      standard_user = standard_user_fixture()
      managed_user = managed_user_fixture(standard_user.default_account)

      EventHandlerMock
      |> expect(:handle_event, fn(event_name, data) ->
          assert event_name == "identity:password_reset_token.create.success"
          assert match_keys(data, [:user])

          {:ok, nil}
         end)

      fields = %{"username" => managed_user.username}
      opts = %{account: standard_user.default_account}

      {:ok, user} = Service.create_password_reset_token(fields, opts)

      assert user.password_reset_token
      assert user.password_reset_token != managed_user.password_reset_token
    end
  end

  #
  # MARK: Password
  #
  describe "update_password/3" do
    test "when password_reset_token is invalid" do
      account = Repo.insert!(%Account{})

      {:error, _} = Service.update_password(%{"reset_token" => "invalid" }, %{"value" => "test1234"}, %{ account: account })
    end

    test "when password_reset_token is valid" do
      account = Repo.insert!(%Account{})
      target_user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.user_name(),
        email: Faker.Internet.safe_email(),
        password_reset_token: "token",
        password_reset_token_expires_at: Timex.shift(Timex.now(), hours: 24),
        encrypted_password: "original"
      })

      {:ok, password} = Service.update_password(%{"reset_token" => "token" }, %{"value" => "test1234"}, %{ account: account })
      assert password.encrypted_value != target_user.encrypted_password
    end

    test "when password provided is invalid" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.user_name(),
        email: Faker.Internet.safe_email(),
        password_reset_token: "token",
        password_reset_token_expires_at: Timex.shift(Timex.now(), hours: 24),
        encrypted_password: "original"
      })

      {:error, changeset} = Service.update_password(%{"reset_token" => "token" }, %{"value" => "test"}, %{ account: account })

      assert changeset.valid? == false
      assert changeset.changes[:value]
    end
  end

  #
  # MARK: Refresh Token
  #
  test "get_refresh_token/1" do
    account = Repo.insert!(%Account{})
    target_refresh_token = Repo.insert!(%RefreshToken{ account_id: account.id })

    refresh_token = Service.get_refresh_token(%{ account: account })

    assert refresh_token
    assert refresh_token.id == target_refresh_token.id
    assert refresh_token.prefixed_id
  end
end
