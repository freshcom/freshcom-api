defmodule BlueJet.Identity.DefaultService do
  use BlueJet, :service
  use BlueJet.EventEmitter, namespace: :identity

  alias Ecto.{Multi, Changeset}
  alias BlueJet.Identity.{Account, User, Password, AccountMembership, RefreshToken, PhoneVerificationCode}

  @behaviour BlueJet.Identity.Service

  def get_vas_data(%{ account_id: nil }) do
    %{ account: nil, user: nil, role: "anonymous" }
  end

  def get_vas_data(%{ account_id: account_id, user_id: nil }) do
    %{ account: get_account(account_id), user: nil, role: "guest" }
  end

  def get_vas_data(%{ account_id: account_id, user_id: user_id }) do
    account = get_account(account_id)
    user = get_user(%{ id: user_id }, %{ account: account }) || get_user(%{ id: user_id }, %{ account_id: account.live_account_id })

    cond do
      account && user -> %{ account: account, user: user, role: user.role }
      account -> %{ account: account, user: nil, role: "guest" }
      true -> %{ account: nil, user: nil, role: "anonymous" }
    end
  end

  def get_vas_data(_) do
    %{ account: nil, user: nil, role: "anonymous" }
  end

  def put_vas_data(request = %{ vas: vas }) do
    %{account: account, user: user, role: role} = get_vas_data(vas)

    request
    |> Map.put(:account, account)
    |> Map.put(:user, user)
    |> Map.put(:role, role)
  end

  #
  # MARK: Account
  #
  def get_account(%{ account_id: nil }), do: nil
  def get_account(%{ account_id: account_id, account: nil }), do: get_account(account_id)
  def get_account(%{ account: account }) when not is_nil(account), do: account
  def get_account(%{ account_id: account_id }), do: get_account(account_id)
  def get_account(map) when is_map(map), do: nil

  def get_account(id) do
    Repo.get(Account, id)
    |> Account.put_test_account_id()
  end

  defp get_account_id(opts) do
    cond do
      opts[:account_id] -> opts[:account_id]
      opts[:account] -> opts[:account].id
      true -> nil
    end
  end

  defp put_account(opts) do
    %{ opts | account: get_account(opts) }
  end

  def create_account(fields) do
    changeset =
      %Account{ mode: "live" }
      |> Account.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:account, changeset)
      |> Multi.run(:test_account, fn(%{ account: account }) ->
          %Account{ live_account_id: account.id, mode: "test" }
          |> Account.changeset(:insert, fields)
          |> Repo.insert()
         end)
      |> Multi.run(:prt_live, fn(%{ account: account }) ->
          prt_live = Repo.insert!(%RefreshToken{ account_id: account.id })
          {:ok, prt_live}
         end)
      |> Multi.run(:prt_test, fn(%{ test_account: test_account }) ->
          prt_test = Repo.insert!(%RefreshToken{ account_id: test_account.id })
          {:ok, prt_test}
         end)
      |> Multi.run(:after_account_create, fn(%{ account: account, test_account: test_account }) ->
          emit_event("identity.account.create.success", %{ account: account, test_account: test_account })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ account: account, test_account: test_account }} ->
        account = %{ account | test_account_id: test_account.id, test_account: test_account }
        {:ok, account}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_account(account = %Account{}, fields, opts \\ %{}) do
    changeset = Account.changeset(account, :update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:account, changeset)
      |> Multi.run(:processed_account, fn(%{ account: account }) ->
          Account.process(account, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_account: account }} ->
        {:ok, account}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def reset_account(account = %Account{ mode: "test" }) do
    changeset = Account.changeset(account, :reset)
    Account.process(account, changeset)

    emit_event("identity.account.reset.success", %{ account: account })

    {:ok, account}
  end

  #
  # MARK: User
  #
  def create_user(fields, %{ account: nil }) do
    account_fields =
      fields
      |> Map.take(["default_locale"])
      |> Map.put("name", fields["account_name"])

    statements =
      Multi.new()
      |> Multi.run(:account, fn(_) ->
          create_account(account_fields)
         end)
      |> Multi.run(:user, fn(%{ account: account }) ->
          %User{ default_account_id: account.id }
          |> User.changeset(:insert, fields)
          |> Repo.insert()
         end)
      |> Multi.run(:account_membership, fn(%{ account: account, user: user }) ->
          account_membership = Repo.insert!(%AccountMembership{
            account_id: account.id,
            user_id: user.id,
            role: "administrator"
          })

          {:ok, account_membership}
         end)
      |> Multi.run(:urt_live, fn(%{ account: account, user: user}) ->
          refresh_token = Repo.insert!(%RefreshToken{ account_id: account.id, user_id: user.id })
          {:ok, refresh_token}
         end)
      |> Multi.run(:urt_test, fn(%{ account: account, user: user}) ->
          refresh_token = Repo.insert!(%RefreshToken{ account_id: account.test_account_id, user_id: user.id })
          {:ok, refresh_token}
         end)
      |> Multi.run(:after_create, fn(%{ user: user }) ->
          emit_event("identity.user.create.success", %{ user: user, account: nil })
          emit_event("identity.email_verification_token.create.success", %{ user: user, account: nil })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ user: user, account: account }} ->
        user = %{ user | default_account: account }
        {:ok, user}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def create_user(fields, %{ account: account }) do
    test_account = Repo.get_by(Account, mode: "test", live_account_id: account.id)

    live_account_id = if test_account do
      account.id
    else
      nil
    end
    test_account_id = if test_account do
      test_account.id
    else
      account.id
    end

    user = %User{
      account_id: account.id,
      account: account,
      default_account_id: account.id,
      default_account: account
    }
    changeset =
      user
      |> User.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:user, changeset)
      |> Multi.run(:account_membership, fn(%{ user: user }) ->
          Repo.insert(%AccountMembership{
            account_id: account.id,
            user_id: user.id,
            role: Map.get(fields, "role")
          })
         end)
      |> Multi.run(:urt_live, fn(%{ user: user }) ->
          if live_account_id do
            refresh_token = Repo.insert!(%RefreshToken{ account_id: live_account_id, user_id: user.id })
            {:ok, refresh_token}
          else
            {:ok, nil}
          end
         end)
      |> Multi.run(:urt_test, fn(%{ user: user }) ->
          if test_account_id do
            refresh_token = Repo.insert!(%RefreshToken{ account_id: test_account_id, user_id: user.id })
            {:ok, refresh_token}
          else
            {:ok, nil}
          end
         end)
      |> Multi.run(:processed_user, fn(%{ user: user }) ->
          User.process(user, changeset)
         end)
      |> Multi.run(:after_create, fn(%{ processed_user: user }) ->
          emit_event("identity.user.create.success", %{ user: user, account: account })

          if user.email do
            emit_event("identity.email_verification_token.create.success", %{ user: user, account: account })
          end

          {:ok, nil}
         end)

    case Repo.transaction(statements) do
      {:ok, %{ user: user }} -> {:ok, user}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def create_user(fields, opts) do
    opts = put_account(opts)
    create_user(fields, opts)
  end

  def get_user(identifiers, opts) do
    account_id = get_account_id(opts)
    filter = extract_nil_filter(identifiers)
    clauses = extract_clauses(identifiers)

    if account_id do
      User.Query.default()
      |> User.Query.member_of_account(account_id)
      |> User.Query.filter_by(filter)
      |> Repo.get_by(clauses)
      |> User.put_role(account_id)
    else
      User.Query.default()
      |> User.Query.global()
      |> User.Query.filter_by(filter)
      |> Repo.get_by(clauses)
    end
  end

  def update_user(nil, _, _), do: {:error, :not_found}

  def update_user(user = %User{}, fields, opts) do
    account = get_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %{ user | account: account }
      |> User.changeset(:update, fields, opts)

    statements =
      Multi.new()
      |> Multi.update(:user, changeset)
      |> Multi.run(:processed_user, fn(%{ user: user}) ->
          User.process(user, changeset)
         end)
      |> Multi.run(:after_update, fn(%{ processed_user: user }) ->
          emit_event("identity.user.update.success", %{ user: user, changeset: changeset, account: account })
         end)
      |> Multi.run(:after_evt_create, fn(%{ processed_user: user }) ->
          if changeset.changes[:email_verification_token] do
            emit_event("identity.email_verification_token.create.success", %{ user: user, account: account })
          else
            {:ok, nil}
          end
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_user: user }} ->
        user = preload(user, preloads[:path], preloads[:opts])
        {:ok, user}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_user(identifiers, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]
    filter = extract_nil_filter(identifiers)
    clauses = extract_clauses(identifiers)

    User.Query.default()
    |> for_account(account.id)
    |> User.Query.filter_by(filter)
    |> Repo.get_by(clauses)
    |> update_user(fields, opts)
  end

  def delete_user(nil, _), do: {:error, :not_found}

  def delete_user(user = %User{}, opts) do
    delete(user, opts)
  end

  def delete_user(identifiers, opts) do
    opts = put_account(opts)
    account = opts[:account]
    filter = extract_nil_filter(identifiers)
    clauses = extract_clauses(identifiers)

    User.Query.default()
    |> for_account(account.id)
    |> User.Query.filter_by(filter)
    |> Repo.get_by(clauses)
    |> delete_user(opts)
  end

  #
  # MARK: Email Verification Token
  #
  def create_email_verification_token(nil), do: {:error, :not_found}

  def create_email_verification_token(user = %User{}) do
    account = user.account || get_account(user)

    statements =
      Multi.new()
      |> Multi.run(:user, fn(_) ->
          user = User.refresh_email_verification_token(user)
          {:ok, user}
         end)
      |> Multi.run(:after_create, fn(%{ user: user }) ->
          emit_event("identity.email_verification_token.create.success", %{ user: user, account: account })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ user: user }} -> {:ok, user}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def create_email_verification_token(%{ "user_id" => nil }, _), do: {:error, :not_found}

  def create_email_verification_token(%{ "user_id" => user_id }, opts) do
    user = get_user(%{ id: user_id }, opts)

    if user do
      %{ user | account: opts[:account] }
      |> create_email_verification_token()
    else
      {:error, :not_found}
    end
  end

  #
  # MARK: Email Verification
  #
  def create_email_verification(nil), do: {:error, :not_found}

  def create_email_verification(user = %{}) do
    User.verify_email(user)
    {:ok, user}
  end

  def create_email_verification(%{ "token" => nil }, _), do: {:error, :not_found}

  def create_email_verification(%{ "token" => token }, opts = %{ account: nil }) when map_size(opts) == 1 do
    User.Query.default()
    |> User.Query.global()
    |> Repo.get_by(email_verification_token: token)
    |> create_email_verification()
  end

  def create_email_verification(%{ "token" => token }, opts = %{ account: account }) when map_size(opts) == 1 do
    User.Query.default()
    |> for_account(account.id)
    |> Repo.get_by(email_verification_token: token)
    |> create_email_verification()
  end

  def create_email_verification(_, _), do: {:error, :not_found}

  #
  # MARK: Password Reset Token
  #

  @doc """
  When an account is provided in `opts`, this function will only search for account
  user otherwise this function will only search for global user.
  """
  def create_password_reset_token(%{ "username" => username }, opts) do
    changeset =
      Changeset.change(%User{}, %{ username: username })
      |> Changeset.validate_required(:username)

    with true <- changeset.valid?,
         user = %User{} <- get_user(%{ username: username }, opts)
    do
      user = User.refresh_password_reset_token(user)
      event_data = Map.merge(opts, %{ user: user })
      emit_event("identity.password_reset_token.create.success", event_data)

      {:ok, user}
    else
      false ->
        {:error, changeset}

      nil ->
        event_data = Map.merge(opts, %{ username: username })
        emit_event("identity.password_reset_token.create.error.username_not_found", event_data)
        {:error, :not_found}
    end
  end

  #
  # MARK: Password
  #

  def update_password(password = %Password{}, new_password) do
    changeset =
      password
      |> Password.changeset(:update, %{ value: new_password })

    case Repo.update(changeset) do
      {:ok, password} ->
        {:ok, password}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_password(nil, _, _), do: {:error, :not_found}

  def update_password(%{ reset_token: reset_token }, new_password, opts = %{ account: nil }) when map_size(opts) == 1 do
    password =
      Password.Query.default()
      |> Password.Query.global()
      |> Repo.get_by(reset_token: reset_token)

    if password do
      update_password(password, new_password)
    else
      {:error, :not_found}
    end
  end

  def update_password(%{ reset_token: reset_token }, new_password, opts = %{ account: account }) when map_size(opts) == 1 do
    password =
      Password.Query.default()
      |> for_account(account.id)
      |> Repo.get_by(reset_token: reset_token)

    if password do
      update_password(password, new_password)
    else
      {:error, :not_found}
    end
  end

  #
  # MARK: Phone Verification Code
  #
  def create_phone_verification_code(fields, opts) do
    account = get_account(opts)

    changeset =
      %PhoneVerificationCode{ account_id: account.id, account: account }
      |> PhoneVerificationCode.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:pvc, changeset)
      |> Multi.run(:after_create, fn(%{ pvc: pvc }) ->
          emit_event("identity.phone_verification_code.create.success", %{ phone_verification_code: pvc, account: account })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ pvc: pvc }} ->
        {:ok, pvc}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  #
  # MARK: Refresh Token
  #
  def get_refresh_token(opts) do
    account = get_account(opts)

    RefreshToken.Query.publishable()
    |> Repo.get_by!(account_id: account.id)
    |> RefreshToken.put_prefixed_id()
  end
end