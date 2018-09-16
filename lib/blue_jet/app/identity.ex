defmodule BlueJet.Identity do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :identity

  alias BlueJet.Identity.{Policy, Service}

  #
  # MARK: Authentication
  #
  def create_access_token(%{fields: fields}) do
    case Service.create_access_token(fields) do
      {:ok, token} ->
        {:ok, %ContextResponse{data: token}}

      {:error, errors} ->
        {:error, %ContextResponse{errors: errors}}
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
  # MARK: User
  #
  def create_user(req), do: default(req, :create, :user, Policy, Service)
  def get_user(req), do: default(req, :get, :user, Policy, Service)
  def update_user(req), do: default(req, :update, :user, Policy, Service)
  def delete_user(req), do: default(req, :delete, :user, Policy, Service)

  #
  # MARK: Account Membership
  #
  def list_account_membership(req), do: default(req, :list, :account_membership, Policy, Service)
  def update_account_membership(req), do: default(req, :update, :account_membership, Policy, Service)

  #
  # MARK: Email Verification
  #
  def create_email_verification_token(req), do: default(req, :create, :email_verification_token, Policy, Service)
  def create_email_verification(req), do: default(req, :create, :email_verification, Policy, &Service.verify_email/2)

  #
  # MARK: Phone Verification Code
  #
  def create_phone_verification_code(req), do: default(req, :create, :phone_verification_code, Policy, Service)

  #
  # MARK: Password
  #
  def create_password_reset_token(req), do: default(req, :create, :password_reset_token, Policy, Service)
  def update_password(req), do: default(req, :update, :password, Policy, Service)

  #
  # MARK: Refresh Token
  #
  def get_refresh_token(req) do
    Policy.authorize(req, :get_refresh_token)
    |> do_get_refresh_token()
  end

  defp do_get_refresh_token({:ok, req}) do
    resp = ContextResponse.put_meta(%ContextResponse{}, :locale, req.locale)

    Service.get_refresh_token(%{account: req._vad_.account})
    |> to_response(:get, resp)
    |> to_result_tuple()
  end

  defp do_get_refresh_token(other), do: other
end
