defmodule BlueJet.Identity.DefaultService do
  use BlueJet, :service

  alias BlueJet.Identity.{
    Account,
    User,
    Password,
    AccountMembership,
    RefreshToken,
    PhoneVerificationCode
  }

  @behaviour BlueJet.Identity.Service

  def get_vas_data(%{account_id: nil}) do
    %{account: nil, user: nil, role: "anonymous"}
  end

  def get_vas_data(%{account_id: account_id, user_id: nil}) do
    %{account: get_account(account_id), user: nil, role: "guest"}
  end

  def get_vas_data(%{account_id: account_id, user_id: user_id}) do
    account = get_account(account_id)

    user =
      get_user(%{id: user_id}, %{account: account}) ||
        get_user(%{id: user_id}, %{account_id: account.live_account_id})

    cond do
      account && user -> %{account: account, user: user, role: user.role}
      account -> %{account: account, user: nil, role: "guest"}
      true -> %{account: nil, user: nil, role: "anonymous"}
    end
  end

  def get_vas_data(_) do
    %{account: nil, user: nil, role: "anonymous"}
  end

  def put_vas_data(request = %{vas: vas}) do
    %{account: account, user: user, role: role} = get_vas_data(vas)

    request
    |> Map.put(:account, account)
    |> Map.put(:user, user)
    |> Map.put(:role, role)
  end

  #
  # MARK: Account
  #
  def get_account(%{id: id}) do
    Repo.get(Account, id)
    |> Account.put_test_account_id()
  end

  def get_account(%{account_id: nil}), do: nil
  def get_account(%{account_id: account_id, account: nil}), do: get_account(%{id: account_id})
  def get_account(%{account: account}) when not is_nil(account), do: account
  def get_account(%{account_id: account_id}), do: get_account(%{id: account_id})
  def get_account(map) when is_map(map), do: nil

  def get_vad(vas) when map_size(vas) == 0, do: %{account: nil, user: nil}
  def get_vad(%{account_id: nil}), do: %{account: nil, user: nil}

  def get_vad(%{account_id: account_id, user_id: nil}) do
    %{account: get_account(%{id: account_id}), user: nil}
  end

  def get_vad(%{account_id: account_id, user_id: user_id}) do
    account = get_account(%{id: account_id})
    user = get_user(%{id: user_id}, %{account: account})

    %{account: account, user: user}
  end

  def get_role(%{account: nil, user: nil}), do: "anonymous"
  def get_role(%{account: _, user: nil}), do: "guest"
  def get_role(%{user: user}), do: user.role

  defp put_account(nil, _), do: nil

  defp put_account(data, account) do
    %{data | account: account}
  end

  @spec create_account(map, map) :: {:ok, Account.t()} | {:error, %{errors: Keyword.t()}}
  def create_account(fields, opts \\ %{}) do
    if opts[:user] && User.type(opts[:user]) == :managed do
      raise ArgumentError, message: "managed user cannot be used to create account"
    end

    statements =
      Multi.new()
      |> Multi.run(:account, fn(_) -> create_live_account(fields) end)
      |> Multi.run(:test_account, &create_test_account(&1, fields))
      |> Multi.run(:dispatch, &dispatch("identity:account.create.success", &1))
      |> Multi.run(:account_membership, fn(%{account: account}) ->
        if opts[:user] do
          do_create_account_membership!(%{account: account, user: opts[:user]}, %{is_owner: true, role: "administrator"})
        else
          {:ok, nil}
        end
      end)

    case Repo.transaction(statements) do
      {:ok, %{account: account, test_account: test_account}} ->
        account = %{account | test_account: test_account, test_account_id: test_account.id}
        {:ok, account}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp create_live_account(fields) do
    %Account{mode: "live"}
    |> do_create_account(fields)
  end

  defp create_test_account(data, fields) do
    %Account{live_account_id: data.account.id, mode: "test"}
    |> do_create_account(fields)
  end

  defp do_create_account(%Account{} = account, fields) do
    changeset = Account.changeset(account, :insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:account, changeset)
      |> Multi.run(:prt, &do_create_refresh_token!(&1))

    case Repo.transaction(statements) do
      {:ok, %{account: account}} ->
        {:ok, account}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp do_create_refresh_token!(data) do
    user_id = (data[:user] || %User{}).id
    refresh_token = Repo.insert!(%RefreshToken{
      account_id: data.account.id,
      user_id: user_id
    })

    {:ok, refresh_token}
  end

  @spec update_account(Account.t(), map, map) :: {:ok, Account.t()} | {:error, %{errors: Keyword.t()}}
  def update_account(account, fields, opts \\ %{})

  def update_account(%Account{mode: "test"}, _, _) do
    {:error, :unprocessable_for_test_account}
  end

  def update_account(%Account{} = account, fields, opts) do
    changeset = Account.changeset(account, :update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:_1, changeset)
      |> Multi.run(:account, &Account.sync_to_test_account(&1[:_1], changeset))

    case Repo.transaction(statements) do
      {:ok, %{account: account}} ->
        {:ok, account}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @spec reset_account(Account.t()) :: {:ok, Account.t()}
  def reset_account(%Account{mode: "test"} = account) do
    statements =
      Multi.new()
      |> Multi.delete_all(:_1, for_account(AccountMembership, account.id))
      |> Multi.delete_all(:_2, for_account(User, account.id))
      |> Multi.delete_all(:_3, for_account(PhoneVerificationCode, account.id))
      |> Multi.run(:dispatch, fn(_) ->
        dispatch("identity:account.reset.success", %{account: account})
      end)

    {:ok, _} = Repo.transaction(statements)
    {:ok, account}
  end

  #
  # MARK: User
  #
  @spec create_user(map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def create_user(fields, %{account: nil}) do
    account_fields =
      fields
      |> Map.take(["default_locale"])
      |> Map.merge(%{"name" => "Unnamed Account"})

    statements =
      Multi.new()
      |> Multi.run(:account, fn(_) -> create_account(account_fields) end)
      |> Multi.run(:user, &do_create_user(%{default_account: &1[:account]}, fields))
      |> Multi.run(:account_membership, &do_create_account_membership!(&1, %{role: "administrator", is_owner: true}))
      |> Multi.run(:urt_live, &do_create_refresh_token!(&1))
      |> Multi.run(:urt_test, &do_create_refresh_token!(%{account: &1[:account].test_account, user: &1[:user]}))
      |> Multi.run(:dispatch1, &dispatch("identity:user.create.success", Map.take(&1, [:user, :account])))
      |> Multi.run(:dispatch2, &dispatch("identity:email_verification_token.create.success", Map.take(&1, [:user, :account])))

    case Repo.transaction(statements) do
      {:ok, %{user: user, account: account}} ->
        {:ok, %{user | default_account: account}}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def create_user(fields, %{account: account} = opts) do
    role = fields["role"] || fields[:role]

    statements =
      Multi.new()
      |> Multi.run(:user, fn(_) -> do_create_user(%{account: account}, fields) end)
      |> Multi.run(:account_membership, &do_create_account_membership!(Map.merge(opts, &1), %{role: role}))
      |> Multi.run(:urt_1, &do_create_refresh_token!(%{user: &1[:user], account: account}))
      |> Multi.run(:urt_2, fn(%{user: user}) ->
        if account.mode == "live" do
          test_account = Repo.get_by!(Account, mode: "test", live_account_id: account.id)
          do_create_refresh_token!(%{account: test_account, user: user})
        else
          {:ok, nil}
        end
      end)
      |> Multi.run(:delete_all_pvc, &do_delete_all_pvc(&1))
      |> Multi.run(:dispatch1, &dispatch("identity:user.create.success", %{user: &1[:user], account: account}))
      |> Multi.run(:dispatch2, fn(%{user: user}) ->
        if user.email do
          dispatch("identity:email_verification_token.create.success", %{user: user, account: account})
        else
          {:ok, nil}
        end
      end)

    case Repo.transaction(statements) do
      {:ok, %{user: user, account_membership: am}} ->
        {:ok, %{user | role: am.role, default_account: account, account: account}}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp do_create_user(data, fields) do
    default_account_id = (data[:default_account] || %Account{}).id
    account_id = (data[:account] || %Account{}).id

    %User{default_account_id: default_account_id || account_id, account_id: account_id}
    |> User.changeset(:insert, fields)
    |> Repo.insert()
  end

  defp do_create_account_membership!(data, fields) do
    account_membership =
      %AccountMembership{account_id: data.account.id, user_id: data.user.id}
      |> AccountMembership.changeset(:insert, fields)
      |> Repo.insert!()

    {:ok, account_membership}
  end

  defp do_delete_all_pvc(%{user: user}) do
    PhoneVerificationCode.Query.default()
    |> PhoneVerificationCode.Query.filter_by(%{phone_number: user.phone_number})
    |> Repo.delete_all()

    {:ok, user}
  end

  @spec get_user(map, map) :: User.t() | nil
  def get_user(identifiers, opts) do
    account = extract_account(opts)
    filter = extract_nil_filter(identifiers)
    clauses = extract_clauses(identifiers)

    do_get_user(filter, clauses, opts)
    |> put_account(account)
  end

  defp do_get_user(filter, clauses, %{type: :managed, account: account}) when not is_nil(account) do
    User.Query.default()
    |> for_account(account.id)
    |> User.Query.filter_by(filter)
    |> Repo.get_by(clauses)
    |> User.put_role(account.id)
  end

  defp do_get_user(filter, clauses, %{account: account}) when not is_nil(account) do
    user =
      User.Query.default()
      |> User.Query.member_of_account(account.id)
      |> User.Query.filter_by(filter)
      |> Repo.get_by(clauses)
      |> User.put_role(account.id)

    if !user && account.mode == "test" do
      do_get_user(filter, clauses, %{account: %Account{id: account.live_account_id}})
    else
      user
    end
  end

  defp do_get_user(filter, clauses, _) do
    User.Query.default()
    |> User.Query.standard()
    |> User.Query.filter_by(filter)
    |> Repo.get_by(clauses)
  end

  @spec update_user(map, map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def update_user(%User{} = user, fields, opts) do
    account = extract_account(opts)

    changeset = User.changeset(user, :update, fields)
    am = Repo.get_by(AccountMembership, account_id: account.id, user_id: user.id)

    statements =
      Multi.new()
      |> Multi.run(:user, fn(_) -> do_update_user(user, fields) end)
      |> Multi.run(:account_membership, fn(_) -> do_update_account_membership(am, fields) end)
      |> Multi.run(:delete_all_pvc, &do_delete_all_pvc(&1))
      |> Multi.run(:dispatch1, fn(_) ->
        dispatch("identity:user.update.success", %{changeset: changeset, account: account})
      end)
      |> Multi.run(:dispatch2, fn(%{user: user}) ->
        if changeset.changes[:email_verification_token] do
          dispatch("identity:email_verification_token.create.success", %{user: user, account: account})
        else
          {:ok, nil}
        end
      end)

    case Repo.transaction(statements) do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_user(nil, _, _), do: {:error, :not_found}

  def update_user(identifiers, fields, opts) do
    account = extract_account(opts)

    user = get_user(identifiers, opts)
    if account.mode == "test" && user && user.account_id != account.id do
      {:error, :unprocessable_for_live_user}
    else
      update_user(user, fields, opts)
    end
  end

  defp do_update_user(user, fields) do
    user
    |> User.changeset(:update, fields)
    |> Repo.update()
  end

  defp do_update_account_membership(account_membership, fields) do
    account_membership
    |> AccountMembership.changeset(:update, fields)
    |> Repo.update()
  end

  @spec delete_user(map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def delete_user(identifiers, opts),
    do: default(:delete, identifiers, Map.put(opts, :type, :managed), &get_user/2)

  #
  # MARK: Account Memebership
  #
  @spec list_account_membership(map, map) :: [AccountMembership.t()]
  def list_account_membership(query, opts \\ %{}) do
    pagination = extract_pagination(opts)
    preload = extract_preload(opts)
    filter = extract_account_membership_filter(query, opts)

    AccountMembership.Query.default()
    |> AccountMembership.Query.search(query[:search])
    |> AccountMembership.Query.filter_by(filter)
    |> sort_by(desc: :inserted_at)
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preload[:paths], preload[:opts])
  end

  @spec count_account_membership(map, map) :: integer
  def count_account_membership(query, opts \\ %{}) do
    filter = extract_account_membership_filter(query, opts)

    AccountMembership.Query.default()
    |> AccountMembership.Query.filter_by(filter)
    |> Repo.aggregate(:count, :id)
  end

  defp extract_account_membership_filter(query, opts) do
    filter = extract_filter(query)

    unless opts[:account] || filter[:user_id] do
      raise ArgumentError, message: "when account is not provided in opts :user_id must be provided as filter"
    end

    if filter[:user_id] do
      filter
    else
      Map.put(filter, :account_id, opts[:account].id)
    end
  end

  @spec get_account_membership(map, map) :: AccountMembership.t() | nil
  def get_account_membership(identifiers, opts),
    do: default(:get, AccountMembership, identifiers, opts)

  @spec update_account_membership(map, map, map) :: {:ok, AccountMembership.t()} | {:error, %{errors: Keyword.t()}}
  def update_account_membership(identifiers, fields, opts),
    do: default(:update, identifiers, fields, opts, &get_account_membership/2)

  #
  # MARK: Email Verification Token
  #
  @evt_error %{errors: [user_id: {"User not found.", code: :not_found}]}

  @spec create_email_verification_token(map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def create_email_verification_token(%{"user_id" => nil}, _), do: {:error, @evt_error}

  def create_email_verification_token(%{"user_id" => user_id}, opts) do
    get_user(%{id: user_id}, opts)
    |> do_create_email_verification_token()
  end

  defp do_create_email_verification_token(nil), do: {:error, @evt_error}

  defp do_create_email_verification_token(%User{} = user) do
    changeset = User.changeset(user, :refresh_email_verification_token)

    statements =
      Multi.new()
      |> Multi.update(:user, changeset)
      |> Multi.run(:dispatch, &dispatch("identity:email_verification_token.create.success", &1))

    case Repo.transaction(statements) do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  #
  # MARK: Email Verification
  #
  @ev_error %{errors: [token: {"Token is invalid or expired.", code: :invalid}]}

  @spec verify_email(map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def verify_email(%{"token" => nil}, _), do: {:error, @ev_error}

  def verify_email(%{"token" => token}, opts) do
    get_user(%{email_verification_token: token}, opts)
    |> do_verify_email()
  end

  defp do_verify_email(nil), do: {:error, @ev_error}

  defp do_verify_email(%User{} = user) do
    changeset = User.changeset(user, :verify_email)

    statements =
      Multi.new()
      |> Multi.update(:user, changeset)
      |> Multi.run(:dispatch, &dispatch("identity:email_verification.create.success", &1))

    case Repo.transaction(statements) do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  #
  # MARK: Phone Verification Code
  #
  @spec create_phone_verification_code(map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def create_phone_verification_code(fields, opts) do
    account = extract_account(opts)

    changeset =
      %PhoneVerificationCode{account_id: account.id, account: account}
      |> PhoneVerificationCode.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:phone_verification_code, changeset)
      |> Multi.run(:dispatch1, &dispatch("identity:phone_verification_code.create.success", &1))

    case Repo.transaction(statements) do
      {:ok, %{phone_verification_code: pvc}} ->
        {:ok, pvc}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  #
  # MARK: Password Reset Token
  #
  @spec create_password_reset_token(map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def create_password_reset_token(%{"username" => username}, _) when byte_size(username) == 0 do
    {:error, %{errors: [username: {"Username is required.", code: :required}]}}
  end

  def create_password_reset_token(fields, %{account: nil} = opts) do
    get_user(%{username: fields["username"]}, opts)
    |> do_create_password_reset_token(opts, fields)
  end

  def create_password_reset_token(fields, %{account: _} = opts) do
    get_user(%{username: fields["username"]}, Map.put(opts, :type, :managed))
    |> do_create_password_reset_token(opts, fields)
  end

  defp do_create_password_reset_token(nil, opts, fields) do
    data = Map.merge(%{username: fields["username"]}, opts)

    Repo.transaction(fn ->
      dispatch("identity:password_reset_token.create.error.username_not_found", data)
    end)

    {:error, %{errors: [username: {"Username not found.", code: :not_found}]}}
  end

  defp do_create_password_reset_token(%User{} = user, _, _) do
    changeset = User.changeset(user, :refresh_password_reset_token)

    statements =
      Multi.new()
      |> Multi.update(:user, changeset)
      |> Multi.run(:dispatch, &dispatch("identity:password_reset_token.create.success", &1))

    case Repo.transaction(statements) do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  #
  # MARK: Password
  #
  @spec update_password(map, map, map) :: {:ok, Password.t()} | {:error, :not_found} | {:error, %{errors: Keyword.t()}}
  def update_password(identifiers, fields, opts) do
    get_password(identifiers, opts)
    |> do_update_password(identifiers, fields)
  end

  defp do_update_password(nil, %{reset_token: _}, _) do
    {:error, %{errors: [reset_token: {"Reset token is invalid or has expired.", code: :invalid}]}}
  end

  defp do_update_password(nil, %{id: _}, _) do
    {:error, :not_found}
  end

  defp do_update_password(%Password{} = password, _, fields) do
    changeset = Password.changeset(password, :update, fields)

    case Repo.update(changeset) do
      {:ok, password} ->
        {:ok, password}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp get_password(%{reset_token: reset_token}, %{account: nil}) do
    Password.Query.default()
    |> Password.Query.standard()
    |> Password.Query.with_valid_reset_token()
    |> Repo.get_by(reset_token: reset_token)
  end

  defp get_password(%{reset_token: reset_token}, %{account: account}) do
    Password.Query.default()
    |> for_account(account.id)
    |> Password.Query.with_valid_reset_token()
    |> Repo.get_by(reset_token: reset_token)
  end

  defp get_password(%{id: id}, %{account: nil}) do
    Password.Query.default()
    |> Password.Query.standard()
    |> Repo.get(id)
  end

  defp get_password(%{id: id}, %{account: account}) do
    Password.Query.default()
    |> for_account(account.id)
    |> Repo.get(id)
  end

  #
  # MARK: Refresh Token
  #
  @spec get_refresh_token(map) :: RefreshToken.t() | nil
  def get_refresh_token(opts) do
    account = extract_account(opts)

    RefreshToken.Query.publishable()
    |> Repo.get_by!(account_id: account.id)
    |> RefreshToken.put_prefixed_id()
  end
end
