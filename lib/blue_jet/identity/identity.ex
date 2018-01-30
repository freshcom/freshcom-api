defmodule BlueJet.Identity do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :identity

  alias BlueJet.Identity.Authorization
  alias BlueJet.Identity.Authentication
  alias BlueJet.Identity.User
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.Service

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
         {:ok, _} <- Repo.update(test_changeset)
    do
      account = Translation.translate(account, request.locale, account.default_locale)
      {:ok, %AccessResponse{ data: account, meta: %{ locale: request.locale } }}
    else
      {:error, changeset} -> {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  #
  # MARK: Email Confirmation
  #
  def create_email_confirmation(request) do
    with {:ok, request} <- preprocess_request(request, "identity.create_email_confirmation") do
      request
      |> do_create_email_confirmation()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_email_confirmation(request) do
    with {:ok, _} <- Service.create_email_confirmation(request.fields, %{ account: request.account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Email Confirmation Token
  #
  def create_email_confirmation_token(request) do
    with {:ok, request} <- preprocess_request(request, "identity.create_email_confirmation_token") do
      request
      |> do_create_email_confirmation_token()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_email_confirmation_token(request) do
    with {:ok, _} <- Service.create_email_confirmation_token(request.fields, %{ account: request.account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
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
      {:error, :not_found} ->
        {:ok, %AccessResponse{}}

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
      {:error, %{ errors: errors }} ->
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

  def do_create_user(request = %{ role: role, account: account, fields: fields }) do
    fields = if role == "guest" do
      Map.merge(fields, %{ "role" => "customer" })
    else
      fields
    end

    with {:ok, user} <- Service.create_user(fields, %{ account: account }) do
      request = %{ request | account: request.account || user.default_account }
      user_response(user, request)
    else
      {:error, %{ errors: errors }} -> {:error, %AccessResponse{ errors: errors }}
    end
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
