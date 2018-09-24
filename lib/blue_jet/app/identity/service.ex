defmodule BlueJet.Identity.Service do
  use BlueJet, :service

  alias BlueJet.Identity.{
    Account,
    User,
    Password,
    AccountMembership,
    RefreshToken,
    PhoneVerificationCode,
    Authentication
  }

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
  # MARK: Authentication
  #
  defdelegate create_access_token(fields), to: Authentication.Service
  defdelegate refresh_tfa_code(user), to: Authentication.Service

  #
  # MARK: Account
  #
  def get_account(%{account_id: nil}), do: nil
  def get_account(%{account_id: account_id, account: nil}), do: get_account(%{id: account_id})
  def get_account(%{account: account}) when not is_nil(account), do: account
  def get_account(%{account_id: account_id}), do: get_account(%{id: account_id})
  def get_account(%{account: nil}), do: nil

  defdelegate create_account(fields, opts \\ %{}), to: Account.Service
  defdelegate get_account(identifiers), to: Account.Service
  defdelegate update_account(account, fields, opts \\ %{}), to: Account.Service
  defdelegate reset_account(account), to: Account.Service

  #
  # MARK: Athorization
  #
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

  #
  # MARK: User
  #
  defdelegate create_user(fields, opts), to: User.Service
  defdelegate get_user(identifiers, opts), to: User.Service
  defdelegate update_user(identifiers_or_user, fields, opts), to: User.Service
  defdelegate delete_user(identifiers_or_user, opts), to: User.Service

  #
  # MARK: Account Memebership
  #
  defdelegate list_account_membership(query, opts \\ %{}), to: AccountMembership.Service
  defdelegate count_account_membership(query, opts \\ %{}), to: AccountMembership.Service
  defdelegate get_account_membership(identifiers, opts), to: AccountMembership.Service
  defdelegate update_account_membership(identifiers, fields, opts), to: AccountMembership.Service

  #
  # MARK: Email Verification Token
  #
  @evt_error %{errors: [user_id: {"User not found.", code: :not_found}]}

  @spec create_email_verification_token(map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def create_email_verification_token(%{"user_id" => nil}, _), do: {:error, @evt_error}

  def create_email_verification_token(%{"user_id" => user_id}, opts) do
    get_user(%{id: user_id}, opts)
    |> do_create_email_verification_token(opts)
  end

  defp do_create_email_verification_token(nil, _), do: {:error, @evt_error}

  defp do_create_email_verification_token(%User{} = user, opts) do
    changeset = User.changeset(user, :refresh_email_verification_token)

    statements =
      Multi.new()
      |> Multi.update(:user, changeset)
      |> Multi.run(:dispatch, &dispatch("identity:email_verification_token.create.success", &1, skip: opts[:skip_dispatch]))

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
    |> do_verify_email(opts)
  end

  defp do_verify_email(nil, _), do: {:error, @ev_error}

  defp do_verify_email(%User{} = user, opts) do
    changeset = User.changeset(user, :verify_email)

    statements =
      Multi.new()
      |> Multi.update(:user, changeset)
      |> Multi.run(:dispatch, &dispatch("identity:email.verify.success", &1, skip: opts[:skip_dispatch]))

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
      |> Multi.run(:dispatch1, &dispatch("identity:phone_verification_code.create.success", &1, skip: opts[:skip_dispatch]))

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
    data =
      opts
      |> Map.merge(%{username: fields["username"]})
      |> Map.take([:username, :account, :type])

    Repo.transaction(fn ->
      dispatch("identity:password_reset_token.create.error.username_not_found", data, skip: opts[:skip_dispatch])
    end)

    {:error, %{errors: [username: {"Username not found.", code: :not_found}]}}
  end

  defp do_create_password_reset_token(%User{} = user, opts, _) do
    changeset = User.changeset(user, :refresh_password_reset_token)

    statements =
      Multi.new()
      |> Multi.update(:user, changeset)
      |> Multi.run(:dispatch, &dispatch("identity:password_reset_token.create.success", &1, skip: opts[:skip_dispatch]))

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

  defp do_update_password(nil, %{"reset_token" => _}, _) do
    {:error, %{errors: [reset_token: {"Reset token is invalid or has expired.", code: :invalid}]}}
  end

  defp do_update_password(nil, %{"id" => _}, _) do
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

  defp get_password(%{"reset_token" => reset_token}, %{account: nil}) do
    Password.Query.default()
    |> Password.Query.standard()
    |> Password.Query.with_valid_reset_token()
    |> Repo.get_by(reset_token: reset_token)
  end

  defp get_password(%{"reset_token" => reset_token}, %{account: account}) do
    Password.Query.default()
    |> for_account(account.id)
    |> Password.Query.with_valid_reset_token()
    |> Repo.get_by(reset_token: reset_token)
  end

  defp get_password(%{"id" => id}, %{account: nil}) do
    Password.Query.default()
    |> Password.Query.standard()
    |> Repo.get(id)
  end

  defp get_password(%{"id" => id}, %{account: account}) do
    Password.Query.default()
    |> for_account(account.id)
    |> Repo.get(id)
  end

  #
  # MARK: Refresh Token
  #
  defdelegate get_refresh_token(opts), to: RefreshToken.Service
end
