defmodule BlueJet.Identity do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :identity

  alias BlueJet.Identity.{Authentication, Policy, Service}

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
  # def list_account(request) do
  #   with {:ok, request} <- preprocess_request(request, "identity.list_account") do
  #     request
  #     |> do_list_account()
  #   else
  #     {:error, _} -> {:error, :access_denied}
  #   end
  # end

  # def do_list_account(request = %{ account: account, vas: %{ user_id: user_id } }) do
  #   accounts =
  #     Account
  #     |> Account.Query.has_member(user_id)
  #     |> Account.Query.live()
  #     |> Repo.all()
  #     |> Translation.translate(request.locale, account.default_locale)

  #   {:ok, %AccessResponse{ data: accounts, meta: %{ locale: request.locale } }}
  # end

  def get_account(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "get_account") do
      do_get_account(authorized_args)
    else
      other -> other
    end
  end

  def do_get_account(args) do
    case Service.get_account(args[:identifiers][:id]) do
      nil ->
        {:error, :not_found}

      account ->
        account = Translation.translate(account, args[:locale], args[:default_locale])
        {:ok, %AccessResponse{ data: account, meta: %{ locale: args[:locale] } }}
    end
  end

  def update_account(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "update_account") do
      do_update_account(authorized_args)
    else
      other -> other
    end
  end

  def do_update_account(args) do
    with {:ok, account} <- Service.update_account(args[:opts][:account], args[:fields], args[:opts]) do
      account = Translation.translate(account, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: account }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def reset_account(request) do
    with {:ok, authorized_args} <- Policy.authorize(request, "reset_account") do
      do_reset_account(authorized_args)
    else
      other -> other
    end
  end

  def do_reset_account(args) do
    account = args[:opts][:account]

    with {:ok, account} <- Service.reset_account(account) do
      account = Translation.translate(account, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: account }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Account Membership
  #
  def list_account_membership(req), do: list("account_membership", req, __MODULE__)
  def update_account_membership(req), do: update("account_membership", req, __MODULE__)

  #
  # MARK: Email Verification Token
  #
  def create_email_verification_token(req), do: create("email_verification_token", req, __MODULE__)

  #
  # MARK: Email Verification
  #
  def create_email_verification(req), do: create("email_verification", req, __MODULE__)

  #
  # MARK: Phone Verification Code
  #
  def create_phone_verification_code(req), do: create("phone_verification_code", req, __MODULE__)

  #
  # MARK: Password Reset Token
  #
  def create_password_reset_token(request) do
    with {:ok, args} <- Policy.authorize(request, "create_password_reset_token"),
         {:ok, user} <- Service.create_password_reset_token(args[:fields], args[:opts])
    do
      {:ok, %AccessResponse{data: user}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Password
  #
  def update_password(request) do
    with {:ok, args} <- Policy.authorize(request, "update_password"),
         {:ok, _} <- Service.update_password(args[:identifiers], args[:fields]["value"], args[:opts])
    do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Refresh Token
  #
  def get_refresh_token(request) do
    with {:ok, args} <- Policy.authorize(request, "get_refresh_token"),
         refresh_token = %{} <- Service.get_refresh_token(args[:opts])
    do
      {:ok, %AccessResponse{ data: refresh_token }}
    else
      nil -> {:error, :not_found}

      other -> other
    end
  end

  #
  # MARK: User
  #
  def create_user(req), do: create("user", req, __MODULE__)
  def get_user(req), do: get("user", req, __MODULE__)
  def update_user(req), do: update("user", req, __MODULE__)
  def delete_user(req), do: delete("user", req, __MODULE__)
end
