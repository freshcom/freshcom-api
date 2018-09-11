defmodule BlueJet.Identity do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :identity

  alias BlueJet.Identity.{Authentication, Policy, Service}

  def create_token(%{ fields: fields }) do
    with {:ok, token} <- Authentication.create_token(fields) do
      {:ok, %ContextResponse{ data: token }}
    else
      {:error, errors} -> {:error, %ContextResponse{ errors: errors }}
    end
  end

  #
  # MARK: Account
  #
  def get_account(req) do
    Policy.authorize(req, :get_account)
    |> do_get_account()
  end

  defp do_get_account({:ok, req}) do
    account = Translation.translate(req._vad_.account, req.locale, req._default_locale_)
    response = %ContextResponse{data: account, meta: %{locale: req.locale}}

    {:ok, response}
  end

  defp do_get_account(other), do: other

  def update_account(req) do
    Policy.authorize(req, :update_account)
    |> do_update_account()
  end

  defp do_update_account({:ok, req}) do
    resp = ContextResponse.put_meta(%ContextResponse{}, :locale, req.locale)

    Service.update_account(req._vad_.account, req.fields, %{locale: req.locale})
    |> to_response(:update, resp)
    |> translate(req.locale, req._default_locale_)
    |> to_result_tuple()
  end

  defp do_update_account(other), do: other

  def reset_account(req) do
    Policy.authorize(req, :reset_account)
    |> do_reset_account()
  end

  defp do_reset_account({:ok, req}) do
    resp = ContextResponse.put_meta(%ContextResponse{}, :locale, req.locale)

    Service.reset_account(req._vad_.account)
    |> to_response(:update, resp)
    |> translate(req.locale, req._default_locale_)
    |> to_result_tuple()
  end

  defp do_reset_account(other), do: other

  #
  # MARK: Account Membership
  #
  def list_account_membership(req), do: default(req, :list, :account_membership, Policy, Service)
  def update_account_membership(req), do: default(req, :update, :account_membership, Policy, Service)

  #
  # MARK: Email Verification Token
  #
  def create_email_verification_token(req), do: default(req, :create, :email_verification_token, Policy, Service)

  #
  # MARK: Email Verification
  #
  def create_email_verification(req), do: default(req, :create, :email_verification, Policy, &Service.verify_email/2)

  #
  # MARK: Phone Verification Code
  #
  def create_phone_verification_code(req), do: default(req, :create, :phone_verification_code, Policy, Service)

  #
  # MARK: Password Reset Token
  #
  def create_password_reset_token(request) do
    with {:ok, args} <- Policy.authorize(request, "create_password_reset_token"),
         {:ok, user} <- Service.create_password_reset_token(args[:fields], args[:opts])
    do
      {:ok, %ContextResponse{data: user}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %ContextResponse{ errors: errors }}

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
      {:ok, %ContextResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %ContextResponse{ errors: errors }}

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
      {:ok, %ContextResponse{ data: refresh_token }}
    else
      nil -> {:error, :not_found}

      other -> other
    end
  end

  #
  # MARK: User
  #
  def create_user(req), do: default(req, :create, :user, Policy, Service)
  # def create_user(req), do: create("user", req, __MODULE__)
  def get_user(req), do: get("user", req, __MODULE__)
  def update_user(req), do: update("user", req, __MODULE__)
  def delete_user(req), do: delete("user", req, __MODULE__)
end
