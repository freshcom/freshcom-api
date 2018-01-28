defmodule BlueJet.Identity do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :identity

  alias BlueJet.Identity.Authorization
  alias BlueJet.Identity.Authentication
  alias BlueJet.Identity.User
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.Account

  defmodule Service do
    alias Ecto.Multi
    alias Ecto.Changeset
    alias BlueJet.Identity

    def get_account(%{ account_id: nil }), do: nil
    def get_account(%{ account_id: account_id, account: nil }), do: get_account(account_id)
    def get_account(%{ account: account }), do: account
    def get_account(id), do: Repo.get!(Account, id)

    def create_user(fields, %{ account: nil }), do: create_user(fields, %{ account_id: nil })
    def create_user(fields, %{ account: account }), do: create_user(fields, %{ account_id: account.id })

    def create_user(fields, opts = %{ account_id: nil }) when map_size(opts) == 1 do

    end

    def create_user(fields, opts = %{ account_id: account_id }) when map_size(opts) == 1 do
      test_account = Repo.get_by(Account, mode: "test", live_account_id: account_id)

      live_account_id = if test_account do
        account_id
      else
        nil
      end
      test_account_id = if test_account do
        test_account.id
      else
        account_id
      end

      user = %User{ default_account_id: account_id, account_id: account_id }
      changeset = User.changeset(user, fields)

      statements =
        Multi.new()
        |> Multi.insert(:user, changeset)
        |> Multi.run(:account_membership, fn(%{ user: user }) ->
            Repo.insert(%AccountMembership{
              account_id: account_id,
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
        |> Multi.run(:after_create, fn(%{ user: user }) ->
            Identity.emit_event("identity.user.after_create", %{ user: user })
           end)

      case Repo.transaction(statements) do
        {:ok, %{ user: user }} -> {:ok, user}
        {:error, _, changeset, _} -> {:error, changeset}
      end
    end

    def create_password_reset_token(email, opts) do
      changeset =
        Changeset.change(%User{}, %{ email: email })
        |> Changeset.validate_required(:email)
        |> Changeset.validate_format(:email, Application.get_env(:blue_jet, :email_regex))

      with true <- changeset.valid?,
           user = %User{} <- get_user_by_email(email, opts)
      do
        user = User.refresh_password_reset_token(user)
        event_data = Map.merge(opts, %{ user: user, email: email })
        Identity.emit_event("identity.password_reset_token.after_create", event_data)

        {:ok, user}
      else
        false ->
          {:error, changeset}

        nil ->
          event_data = Map.merge(opts, %{ user: nil, email: email })
          Identity.emit_event("identity.password_reset_token.not_created", event_data)
          {:ok, nil}
      end
    end

    def create_password(user = %{}, new_password) do
      changeset =
        Changeset.change(%User{}, %{ password: new_password })
        |> Changeset.validate_required(:password)
        |> Changeset.validate_length(:password, min: 8)

      if changeset.valid? do
        user =
          user
          |> User.refresh_password_reset_token()
          |> User.update_password(new_password)

        {:ok, user}
      else
        {:error, changeset}
      end
    end

    def create_password(nil, _, _), do: {:error, :not_found}

    def create_password(password_reset_token, new_password, opts = %{ account: nil }) when map_size(opts) == 1 do
      user =
        User.Query.default()
        |> User.Query.global()
        |> Repo.get_by(password_reset_token: password_reset_token)

      if user do
        create_password(user, new_password)
      else
        {:error, :not_found}
      end
    end

    def create_password(password_reset_token, new_password, opts = %{ account: account }) when map_size(opts) == 1 do
      user =
        User.Query.default()
        |> User.Query.for_account(account.id)
        |> Repo.get_by(password_reset_token: password_reset_token)

      if user do
        create_password(user, new_password)
      else
        {:error, :not_found}
      end
    end

    defp get_user_by_email(email, opts = %{ account: nil }) when map_size(opts) == 1 do
      get_user_by_email(email, %{})
    end

    defp get_user_by_email(email, opts) when map_size(opts) == 0 do
      User.Query.default()
      |> User.Query.global()
      |> Repo.get_by(email: email)
    end

    defp get_user_by_email(email, opts) do
      account_id = opts[:account_id] || opts[:account].id

      User.Query.default()
      |> User.Query.for_account(account_id)
      |> Repo.get_by(email: email)
    end
  end

  defmodule Query do
    alias Ecto.Multi
    alias BlueJet.Identity

    def create_account(fields) do
      Multi.new()
      |> Multi.insert(:account, Account.changeset(%Account{ mode: "live" }, fields))
      |> Multi.run(:test_account, fn(%{ account: account }) ->
          changeset = Account.changeset(%Account{ live_account_id: account.id, mode: "test" }, fields)
          Repo.insert(changeset)
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
          Identity.emit_event("identity.account.after_create", %{ account: account, test_account: test_account })
         end)
    end

    def create_global_user(fields) do
      account_fields =
        fields
        |> Map.take(["default_locale"])
        |> Map.put("name", fields["account_name"])

      Multi.new()
      |> Multi.append(create_account(account_fields))
      |> Multi.run(:user, fn(%{ account: account }) ->
          changeset = User.changeset(%User{ default_account_id: account.id }, fields)
          Repo.insert(changeset)
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
      |> Multi.run(:urt_test, fn(%{ test_account: test_account, user: user}) ->
          refresh_token = Repo.insert!(%RefreshToken{ account_id: test_account.id, user_id: user.id })
          {:ok, refresh_token}
         end)
    end

    def create_account_user(account_id, fields) do
      test_account = Repo.get_by(Account, mode: "test", live_account_id: account_id)

      live_account_id = if test_account do
        account_id
      else
        nil
      end
      test_account_id = if test_account do
        test_account.id
      else
        account_id
      end

      changeset = User.changeset(%User{ default_account_id: account_id, account_id: account_id }, fields)
      Multi.new()
      |> Multi.insert(:user, changeset)
      |> Multi.run(:account_membership, fn(%{ user: user }) ->
          Repo.insert(%AccountMembership{
            account_id: account_id,
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
    end
  end

  #### TODO: TOBE REMOVED
  def authorize(vas = %{}, endpoint) do
    Authorization.authorize(vas, endpoint)
  end

  def authorize_request(request = %{ vas: vas }, endpoint) do
    with {:ok, %{ role: role, account: account }} <- authorize(vas, endpoint) do
      {:ok, %{ request | role: role, account: account }}
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  #####

  def create_token(%{ fields: fields }) do
    with {:ok, token} <- Authentication.create_token(fields) do
      {:ok, %AccessResponse{ data: token }}
    else
      {:error, errors} -> {:error, %AccessResponse{ errors: errors }}
    end
  end

  #
  # MARK: Account
  #
  def list_account(request) do
    with {:ok, request} <- preprocess_request(request, "identity.list_account") do
      request
      |> do_list_account()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_account(request = %{ account: account, vas: %{ user_id: user_id } }) do
    accounts =
      Account
      |> Account.Query.has_member(user_id)
      |> Account.Query.live()
      |> Repo.all()
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ data: accounts, meta: %{ locale: request.locale } }}
  end

  def get_account(request) do
    with {:ok, request} <- preprocess_request(request, "identity.get_account") do
      request
      |> do_get_account()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_account(request = %{ account: account }) do
    account =
      account
      |> Translation.translate(request.locale, account.default_locale)
      |> Account.put_test_account_id()

    {:ok, %AccessResponse{ data: account, meta: %{ locale: request.locale } }}
  end

  def update_account(request) do
    with {:ok, request} <- preprocess_request(request, "identity.update_account") do
      request
      |> do_update_account()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_account(request = %{ account: account, fields: fields }) do
    live_changeset = Account.changeset(account, fields, request.locale)

    test_account = Repo.get_by(Account, live_account_id: account.id)
    test_changeset = Account.changeset(test_account, fields, request.locale)

    with {:ok, account} <- Repo.update(live_changeset),
         {:ok, test_account} <- Repo.update(test_changeset)
    do
      account = Translation.translate(account, request.locale, account.default_locale)
      {:ok, %AccessResponse{ data: account, meta: %{ locale: request.locale } }}
    else
      {:error, changeset} -> {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  #
  # MARK: Password Reset Token
  #
  def create_password_reset_token(request) do
    with {:ok, request} <- preprocess_request(request, "identity.create_password_reset_token") do
      request
      |> do_create_password_reset_token()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  @doc """
  Create a password reset token. The created token will be saved to the database
  but will not be returned in the response.

  When the provided account is nil, this function will only search for global user
  and if found will create the token then sent an corresponding email to the user.

  When an account is provided, this function will only search for account
  user and if found will create the token. An corresponding email may or may not be send
  depending on if a trigger is set to the account.
  """
  def do_create_password_reset_token(request) do
    with {:ok, _} <- Service.create_password_reset_token(request.fields["email"], %{ account: request.account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  #
  # MARK: Password
  #
  def create_password(request) do
    with {:ok, request} <- preprocess_request(request, "identity.create_password") do
      request
      |> do_create_password()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_password(request) do
    with {:ok, _} <- Service.create_password(request.fields["token"], request.fields["value"], %{ account: request.account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, changeset = %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: [value: errors[:password]] }}

      other -> other
    end
  end

  #
  # MARK: User
  #
  defp user_response(nil, _), do: {:error, :not_found}

  defp user_response(user, request = %{ account: account }) do
    preloads = User.Query.preloads(request.preloads, role: request.role)

    user =
      user
      |> User.put_role(account)
      |> Repo.preload(preloads)
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: user }}
  end

  def create_user(request) do
    with {:ok, request} <- preprocess_request(request, "identity.create_user") do
      request
      |> do_create_user()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_user(request = %{ role: "anonymous", fields: fields }) do
    Query.create_global_user(fields)
    |> Repo.transaction()
    |> do_create_user_response(request)
  end

  def do_create_user(request = %{ role: "guest", account: account, fields: fields }) do
    fields = Map.merge(fields, %{ "role" => "customer" })

    with {:ok, user} <- Service.create_user(fields, %{ account: account }) do
      user_response(user, request)
    else
      {:error, %{ errors: errors }} -> {:error, %AccessResponse{ errors: errors }}
    end
  end

  def do_create_user(request = %{ account: account, fields: fields }) do
    Query.create_account_user(account.id, fields)
    |> Repo.transaction()
    |> do_create_user_response(request)
  end

  # Global user
  def do_create_user_response({:ok, %{ user: user, account: account }}, request) do
    user_response(user, %{ request | account: account })
  end

  # Account user
  def do_create_user_response({:ok, %{ user: user }}, request) do
    user_response(user, request)
  end

  def do_create_user_response({:error, _, failed_value, _}, _) do
    {:error, %AccessResponse{ errors: failed_value.errors }}
  end

  def get_user(request) do
    with {:ok, request} <- preprocess_request(request, "identity.get_user") do
      request
      |> do_get_user()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_user(request = %{ vas: %{ user_id: user_id } }) do
    User
    |> Repo.get(user_id)
    |> user_response(request)
  end

  def update_user(request) do
    with {:ok, request} <- preprocess_request(request, "identity.update_user") do
      request
      |> do_update_user()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_user(request = %{ role: role, vas: vas }) when role not in ["administrator"] do
    user = Repo.get(User, vas[:user_id])

    with %User{} <- user,
         changeset <- User.changeset(user, request.fields),
         {:ok, user} <- Repo.update(changeset)
    do
      user_response(user, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      nil ->
        {:error, :not_found}
    end
  end

  def delete_user(request = %{ vas: vas, params: %{ "id" => id } }) do
    with {:ok, request} <- preprocess_request(request, "identity.delete_user") do
      cond do
        # Customer user cannot delete a user other than himself
        request.role == "customer" && vas[:user_id] != id ->
          {:error, :access_denied}

        # Allow other role to delete
        true ->
          request
          |> do_delete_user()
      end
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_user(%{ account: account, params: %{ "id" => id } }) do
    user =
      User.Query.default()
      |> User.Query.for_account(account.id)
      |> Repo.get(id)

    if user do
      Repo.delete!(user)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end

  #
  # RefreshToken
  #
  def get_refresh_token(request) do
    with {:ok, request} <- preprocess_request(request, "identity.get_refresh_token") do
      request
      |> do_get_refresh_token()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_refresh_token(%{ account: account }) do
    refresh_token =
      RefreshToken.Query.publishable()
      |> Repo.get_by(account_id: account.id)

    if refresh_token do
      refresh_token = %{ refresh_token | prefixed_id: RefreshToken.get_prefixed_id(refresh_token) }
      {:ok, %AccessResponse{ data: refresh_token }}
    else
      {:error, :not_found}
    end
  end
end
