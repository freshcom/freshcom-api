defmodule BlueJet.Identity.Policy do
  alias BlueJet.ContextRequest
  alias BlueJet.Identity.Service

  # TODO: Fix this
  def authorize(%{vas: vas, _role_: nil} = req, endpoint) do
    vad = Service.get_vad(vas)
    role = Service.get_role(vad)
    default_locale = if vad[:account], do: vad[:account].default_locale, else: nil

    req
    |> Map.put(:_vad_, vad)
    |> Map.put(:_role_, role)
    |> Map.put(:_default_locale_, default_locale)
    |> authorize(endpoint)
  end

  #
  # MARK: Account
  #
  def authorize(%{_role_: role}, :get_account) when role in ["anonymous"] do
    {:error, :access_denied}
  end

  def authorize(req, :get_account) do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_account)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :reset_account)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Account Membership
  #
  def authorize(%{_role_: role, params: %{"target" => "user"}}, :list_account_membership)
      when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(%{_vad_: %{user: user}, params: %{"target" => "user"}} = req, :list_account_membership) do
    req =
      req
      |> ContextRequest.put(:filter, :user_id, user.id)
      |> ContextRequest.put(:_scope_, :user_id, user.id)
      |> ContextRequest.put(:_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role, _vad_: %{account: account}} = req, :list_account_membership) when role in ["administrator"] do
    req =
      req
      |> ContextRequest.put(:filter, :account_id, account.id)
      |> ContextRequest.put(:_scope_, :account_id, account.id)
      |> ContextRequest.put(:_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_account_membership) when role in ["administrator"] do
    req = ContextRequest.put(req, :_preload_, :paths, req.preloads)

    {:ok, req}
  end

  #
  # MARK: Email Verification
  #
  def authorize(%{_role_: role}, :create_email_verification_token)
      when role in ["anonymous", "guest"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role} = req, :create_email_verification_token)
      when not is_nil(role) do
    req = ContextRequest.put(req, :fields, "user_id", req.vas[:user_id])
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_email_verification) when not is_nil(role) do
    {:ok, req}
  end

  #
  # MARK: Phone Verification Code
  #
  def authorize(%{_role_: role}, :create_phone_verification_code) when role in ["anonymous"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role} = req, :create_phone_verification_code) when not is_nil(role) do
    {:ok, req}
  end

  #
  # MARK: Password
  #
  def authorize(%{_role_: role} = req, :create_password_reset_token) when not is_nil(role) do
    {:ok, req}
  end

  def authorize(%{_role_: role, identifiers: %{reset_token: _}} = req, :update_password) when not is_nil(role) do
    {:ok, req}
  end

  def authorize(%{_role_: role, identifiers: %{id: _}} = req, :update_password) when role in ["administrator"] do
    {:ok, req}
  end

  #
  # MARK: Refresh Token
  #
  def authorize(%{_role_: role} = req, :get_refresh_token)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: User
  #
  def authorize(%{_role_: "guest"} = req, :create_user) do
    req = ContextRequest.put(req, :fields, "role", "customer")
    {:ok, req}
  end

  def authorize(%{_role_: role} = req,  :create_user)
      when role in ["anonymous", "developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role}, :get_user) when role in ["anonymous", "guest"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role, _vad_: %{user: user}} = req, :get_user)
      when role in ["developer", "administrator"] do
    id = req.identifiers[:id] || user.id
    type = if id == user.id, do: :standard, else: :managed

    req =
      req
      |> ContextRequest.put(:identifiers, :id, id)
      |> ContextRequest.put(:_opts_, :type, type)

    {:ok, req}
  end

  def authorize(%{_role_: role, _vad_: %{user: user}} = req, :get_user) when not is_nil(role) do
    req = ContextRequest.put(req, :identifiers, :id, user.id)

    {:ok, req}
  end

  def authorize(%{_role_: role}, :update_user) when role in ["anonymous", "guest"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role, _vad_: %{user: user}} = req, :update_user)
      when role in ["developer", "administrator"] do
    id = req.identifiers[:id] || user.id
    type = if id == user.id, do: :standard, else: :managed

    req =
      req
      |> ContextRequest.put(:identifiers, :id, id)
      |> ContextRequest.put(:_opts_, :type, type)

    {:ok, req}
  end

  def authorize(%{_role_: role, _vad_: %{user: user}} = req, :update_user) when not is_nil(role) do
    req = ContextRequest.put(req, :identifiers, :id, user.id)

    {:ok, req}
  end

  def authorize(%{_role_: role, _vad_: %{user: user}} = req, :delete_user)
      when role in ["developer", "administrator"] do
    id = req.identifiers[:id] || user.id

    req =
      req
      |> ContextRequest.put(:identifiers, :id, id)
      |> ContextRequest.put(:_opts_, :type, :managed)

    {:ok, req}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
