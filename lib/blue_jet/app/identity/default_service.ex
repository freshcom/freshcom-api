defmodule BlueJet.Identity.DefaultService do
  use BlueJet, :service
  use BlueJet.EventEmitter, namespace: :identity

  alias Ecto.{Multi, Changeset}

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

  defp get_account_id(opts) do
    cond do
      opts[:account_id] -> opts[:account_id]
      opts[:account] -> opts[:account].id
      true -> nil
    end
  end

  defp put_account(opts) do
    %{opts | account: get_account(opts)}
  end

  @spec create_account(map) :: {:ok, Account.t()} | {:error, Changeset.t()}
  def create_account(fields) do
    statements =
      Multi.new()
      |> Multi.run(:account, fn(_) -> create_live_account(fields) end)
      |> Multi.run(:test_account, &create_test_account(fields, &1))
      |> Multi.run(:dispatch_event, &dispatch("identity:account.create.success", &1))

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

  defp create_test_account(fields, opts) do
    %Account{live_account_id: opts.account.id, mode: "test"}
    |> do_create_account(fields)
  end

  defp do_create_account(%Account{} = account, fields) do
    changeset = Account.changeset(account, :insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:account, changeset)
      |> Multi.run(:prt, fn(%{account: account}) ->
        {:ok, Repo.insert!(%RefreshToken{account_id: account.id})}
      end)

    case Repo.transaction(statements) do
      {:ok, %{account: account}} ->
        {:ok, account}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @spec update_account(Account.t(), map, map) :: {:ok, Account.t()} | {:error, Changeset.t()}
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
      |> Multi.run(:dispatch_event, fn(_) ->
        dispatch("identity:account.reset.success", %{account: account})
      end)

    {:ok, _} = Repo.transaction(statements)
    {:ok, account}
  end

  #
  # MARK: Account Memebership
  #
  def list_account_membership(fields \\ %{}, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preloads = extract_preloads(opts, account)
    filter = extract_filter(fields)

    AccountMembership.Query.default()
    |> AccountMembership.Query.search(fields[:search])
    |> AccountMembership.Query.filter_by(filter)
    |> sort_by(desc: :inserted_at)
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_account_membership(fields \\ %{}, _) do
    filter = extract_filter(fields)

    AccountMembership.Query.default()
    |> AccountMembership.Query.filter_by(filter)
    |> Repo.aggregate(:count, :id)
  end

  def get_account_membership(identifiers, opts) do
    get(AccountMembership, identifiers, opts)
  end

  def update_account_membership(nil, _, _), do: {:error, :not_found}

  def update_account_membership(membership = %AccountMembership{}, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %{ membership | account: account }
      |> AccountMembership.changeset(:update, fields)

    with {:ok, membership} <- Repo.update(changeset) do
      membership = preload(membership, preloads[:path], preloads[:opts])
      {:ok, membership}
    else
      other -> other
    end
  end

  def update_account_membership(identifiers, fields, opts) do
    get_account_membership(identifiers, opts)
    |> update_account_membership(fields, opts)
  end

  #
  # MARK: User
  #
  def create_user(fields, %{account: nil}) do
    account_fields =
      fields
      |> Map.take(["default_locale"])
      |> Map.merge(%{"name" => "Unnamed Account"})

    statements =
      Multi.new()
      |> Multi.run(:account, fn _ ->
        create_account(account_fields)
      end)
      |> Multi.run(:user, fn %{account: account} ->
        %User{default_account_id: account.id}
        |> User.changeset(:insert, fields)
        |> Repo.insert()
      end)
      |> Multi.run(:account_membership, fn %{account: account, user: user} ->
        account_membership =
          Repo.insert!(%AccountMembership{
            account_id: account.id,
            user_id: user.id,
            role: "administrator",
            is_owner: true
          })

        {:ok, account_membership}
      end)
      |> Multi.run(:urt_live, fn %{account: account, user: user} ->
        refresh_token = Repo.insert!(%RefreshToken{account_id: account.id, user_id: user.id})
        {:ok, refresh_token}
      end)
      |> Multi.run(:urt_test, fn %{account: account, user: user} ->
        refresh_token =
          Repo.insert!(%RefreshToken{account_id: account.test_account_id, user_id: user.id})

        {:ok, refresh_token}
      end)
      |> Multi.run(:after_create, fn %{user: user} ->
        emit_event("identity.user.create.success", %{user: user, account: nil})

        emit_event("identity.email_verification_token.create.success", %{user: user, account: nil})
      end)

    case Repo.transaction(statements) do
      {:ok, %{user: user, account: account}} ->
        user = %{user | default_account: account}
        {:ok, user}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def create_user(fields, %{account: account}) do
    test_account = Repo.get_by(Account, mode: "test", live_account_id: account.id)

    live_account_id =
      if test_account do
        account.id
      else
        nil
      end

    test_account_id =
      if test_account do
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
      |> Multi.run(:account_membership, fn %{user: user} ->
          %AccountMembership{ account_id: account.id, user_id: user.id }
          |> AccountMembership.changeset(:insert, %{ role: Map.get(fields, "role") || Map.get(fields, :role) })
          |> Repo.insert()
      end)
      |> Multi.run(:urt_live, fn %{user: user} ->
        if live_account_id do
          refresh_token =
            Repo.insert!(%RefreshToken{account_id: live_account_id, user_id: user.id})

          {:ok, refresh_token}
        else
          {:ok, nil}
        end
      end)
      |> Multi.run(:urt_test, fn %{user: user} ->
        if test_account_id do
          refresh_token =
            Repo.insert!(%RefreshToken{account_id: test_account_id, user_id: user.id})

          {:ok, refresh_token}
        else
          {:ok, nil}
        end
      end)
      |> Multi.run(:_, fn %{user: user} ->
        User.delete_all_pvc(user)
      end)
      |> Multi.run(:after_create, fn %{user: user} ->
        emit_event("identity.user.create.success", %{user: user, account: account})

        if user.email do
          emit_event("identity.email_verification_token.create.success", %{
            user: user,
            account: account
          })
        end

        {:ok, nil}
      end)

    case Repo.transaction(statements) do
      {:ok, %{ user: user, account_membership: am }} ->
        {:ok, %{ user | role: am.role }}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def create_user(fields, opts) do
    opts = put_account(opts)
    create_user(fields, opts)
  end

  def get_user(identifiers, opts) do
    account_id = get_account_id(opts)
    account = get_account(opts)
    filter = extract_nil_filter(identifiers)
    clauses = extract_clauses(identifiers)

    cond do
      account_id && opts[:type] == :managed ->
        User.Query.default()
        |> for_account(account_id)
        |> User.Query.filter_by(filter)
        |> Repo.get_by(clauses)
        |> User.put_role(account_id)

      account_id ->
        user =
          User.Query.default()
          |> User.Query.member_of_account(account_id)
          |> User.Query.filter_by(filter)
          |> Repo.get_by(clauses)
          |> User.put_role(account_id)

        if !user && account.mode == "test" do
          User.Query.default()
          |> User.Query.member_of_account(account.live_account_id)
          |> User.Query.filter_by(filter)
          |> Repo.get_by(clauses)
          |> User.put_role(account.live_account_id)
        else
          user
        end

      true ->
        User.Query.default()
        |> User.Query.standard()
        |> User.Query.filter_by(filter)
        |> Repo.get_by(clauses)
    end
  end

  def update_user(nil, _, _), do: {:error, :not_found}

  def update_user(user = %User{}, fields, opts) do
    account = get_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %{user | account: account}
      |> User.changeset(:update, fields, opts)

    membership = Repo.get_by(AccountMembership, user_id: user.id, account_id: account.id)
    membership_changeset =
      %{membership | account: account}
      |> AccountMembership.changeset(:update, fields)

    statements =
      Multi.new()
      |> Multi.update(:user, changeset)
      |> Multi.update(:membership, membership_changeset)
      |> Multi.run(:_, fn %{user: user} ->
        User.delete_all_pvc(user)
      end)
      |> Multi.run(:after_update, fn %{user: user} ->
        emit_event("identity.user.update.success", %{
          user: user,
          changeset: changeset,
          account: account
        })
      end)
      |> Multi.run(:after_evt_create, fn %{user: user} ->
        if changeset.changes[:email_verification_token] do
          emit_event("identity.email_verification_token.create.success", %{
            user: user,
            account: account
          })
        else
          {:ok, nil}
        end
      end)

    case Repo.transaction(statements) do
      {:ok, %{user: user}} ->
        user = preload(user, preloads[:path], preloads[:opts])
        {:ok, user}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_user(identifiers, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    user = get_user(identifiers, opts)
    if opts[:type] != :managed && account.mode == "test" && user.account_id != account.id do
      {:error, :unprocessable_for_live_user}
    else
      update_user(user, fields, opts)
    end
  end

  def delete_user(nil, _), do: {:error, :not_found}

  def delete_user(user = %User{}, opts) do
    delete(user, opts)
  end

  def delete_user(identifiers, opts) do
    opts = put_account(opts)

    get_user(identifiers, opts)
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
      |> Multi.run(:user, fn _ ->
        user = User.refresh_email_verification_token(user)
        {:ok, user}
      end)
      |> Multi.run(:after_create, fn %{user: user} ->
        emit_event("identity.email_verification_token.create.success", %{
          user: user,
          account: account
        })
      end)

    case Repo.transaction(statements) do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def create_email_verification_token(%{"user_id" => nil}, _), do: {:error, :not_found}

  def create_email_verification_token(%{"user_id" => user_id}, opts) do
    user = get_user(%{id: user_id}, opts)

    if user do
      %{user | account: opts[:account]}
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

  def create_email_verification(%{"token" => nil}, _), do: {:error, :not_found}

  def create_email_verification(%{"token" => token}, %{account: nil}) do
    User.Query.default()
    |> User.Query.standard()
    |> Repo.get_by(email_verification_token: token)
    |> create_email_verification()
  end

  def create_email_verification(%{"token" => token}, %{account: account}) do
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
  When an account is provided in `opts`, this function will only search for managed
  user otherwise this function will only search for standard user.
  """
  def create_password_reset_token(fields, opts) do
    changeset =
      Changeset.change(%User{}, %{username: fields["username"]})
      |> Changeset.validate_required(:username)

    with true <- changeset.valid?,
         user = %User{} <- get_user(%{username: fields["username"]}, opts) do
      user = User.refresh_password_reset_token(user)
      event_data = Map.merge(opts, %{user: user})
      emit_event("identity.password_reset_token.create.success", event_data)

      {:ok, user}
    else
      false ->
        {:error, changeset}

      nil ->
        event_data = Map.merge(opts, %{username: fields["username"]})
        emit_event("identity.password_reset_token.create.error.username_not_found", event_data)
        {:error, %{errors: [username: {"Username not found", code: :not_found}]}}
    end
  end

  #
  # MARK: Password
  #
  def update_password(password = %Password{}, new_password) do
    changeset =
      password
      |> Password.changeset(:update, %{value: new_password, reset_token: nil, reset_token_expires_at: nil})

    case Repo.update(changeset) do
      {:ok, password} ->
        {:ok, password}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_password(nil, _, _), do: {:error, :not_found}

  def update_password(%{reset_token: reset_token}, new_password, %{account: nil}) do
    password =
      Password.Query.default()
      |> Password.Query.standard()
      |> Password.Query.with_valid_reset_token()
      |> Repo.get_by(reset_token: reset_token)

    if password do
      update_password(password, new_password)
    else
      {:error, %{errors: [reset_token: {"Reset token is invalid or has expired.", code: :invalid}]}}
    end
  end

  def update_password(%{reset_token: reset_token}, new_password, %{account: account}) do
    password =
      Password.Query.default()
      |> for_account(account.id)
      |> Password.Query.with_valid_reset_token()
      |> Repo.get_by(reset_token: reset_token)

    if password do
      update_password(password, new_password)
    else
      {:error, %{errors: [reset_token: {"Reset token is invalid or has expired.", code: :invalid}]}}
    end
  end

  def update_password(%{id: id}, new_password, %{account: nil}) do
    password =
      Password.Query.default()
      |> Password.Query.standard()
      |> Repo.get(id)

    if password do
      update_password(password, new_password)
    else
      {:error, :not_found}
    end
  end

  def update_password(%{id: id}, new_password, %{account: account}) do
    password =
      Password.Query.default()
      |> for_account(account.id)
      |> Repo.get(id)

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
      %PhoneVerificationCode{account_id: account.id, account: account}
      |> PhoneVerificationCode.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:pvc, changeset)
      |> Multi.run(:after_create, fn %{pvc: pvc} ->
        emit_event("identity.phone_verification_code.create.success", %{
          phone_verification_code: pvc,
          account: account
        })
      end)

    case Repo.transaction(statements) do
      {:ok, %{pvc: pvc}} ->
        {:ok, pvc}

      {:error, _, changeset, _} ->
        {:error, changeset}
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