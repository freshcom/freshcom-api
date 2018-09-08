defmodule BlueJet.Identity.Policy do
  import BlueJet.Policy.AuthorizedRequest

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
  # MARK: Email Verification Token
  #
  def authorize(%{role: role}, "create_email_verification_token")
      when role in ["anonymous", "guest"] do
    {:error, :access_denied}
  end

  def authorize(request = %{role: role}, "create_email_verification_token")
      when not is_nil(role) do
    {:ok, from_access_request(request, :create)}
  end

  #
  # MARK: Email Verification
  #
  def authorize(request = %{role: role}, "create_email_verification") when not is_nil(role) do
    {:ok, from_access_request(request, :create)}
  end

  #
  # MARK: Phone Verification Code
  #
  def authorize(%{role: role}, "create_phone_verification_code") when role in ["anonymous"] do
    {:error, :access_denied}
  end

  def authorize(request = %{role: role}, "create_phone_verification_code")
      when not is_nil(role) do
    {:ok, from_access_request(request, :create)}
  end

  #
  # MARK: Password Reset Token
  #
  def authorize(request = %{role: role}, "create_password_reset_token") when not is_nil(role) do
    {:ok, from_access_request(request, :create)}
  end

  #
  # MARK: Password
  #
  def authorize(request = %{role: role, fields: %{"reset_token" => _}}, "update_password") when not is_nil(role) do
    authorized_args = from_access_request(request, :update)

    identifiers =
      Map.merge(authorized_args[:identifiers], %{
        reset_token: authorized_args[:fields]["reset_token"]
      })

    authorized_args = %{authorized_args | identifiers: identifiers}

    {:ok, authorized_args}
  end

  def authorize(request = %{role: role, params: %{"id" => _}}, "update_password") when role in ["administrator"] do
    {:ok, from_access_request(request, :update)}
  end

  #
  # MARK: Refresh Token
  #
  def authorize(request = %{role: role}, "get_refresh_token")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
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

  def authorize(%{role: role}, "get_user") when role in ["anonymous", "guest"] do
    {:error, :access_denied}
  end

  def authorize(request = %{role: role, user: user}, "get_user")
      when role in ["developer", "administrator"] do
    authorized_args = from_access_request(request, :get)

    id = authorized_args[:identifiers][:id] || user.id
    type = if id == user.id, do: :standard, else: :managed
    identifiers = %{authorized_args[:identifiers] | id: id}
    opts = Map.put(authorized_args[:opts], :type, type)
    authorized_args = %{authorized_args | identifiers: identifiers, opts: opts}

    {:ok, authorized_args}
  end

  def authorize(request = %{role: role, user: user}, "get_user") when not is_nil(role) do
    authorized_args = from_access_request(request, :get)

    identifiers = Map.merge(authorized_args[:identifiers], %{id: user.id})
    authorized_args = %{authorized_args | identifiers: identifiers}

    {:ok, authorized_args}
  end

  def authorize(%{role: role}, "update_user") when role in ["anonymous", "guest"] do
    {:error, :access_denied}
  end

  def authorize(request = %{role: role, user: user}, "update_user")
      when role in ["developer", "administrator"] do
    authorized_args = from_access_request(request, :update)

    id = authorized_args[:identifiers][:id] || user.id
    type = if id == user.id, do: :standard, else: :managed
    identifiers = %{authorized_args[:identifiers] | id: id}
    opts = Map.put(authorized_args[:opts], :type, type)
    authorized_args = %{authorized_args | identifiers: identifiers, opts: opts}

    {:ok, authorized_args}
  end

  def authorize(request = %{role: role, user: user}, "update_user") when not is_nil(role) do
    authorized_args = from_access_request(request, :update)

    identifiers = Map.merge(authorized_args[:identifiers], %{id: user.id})
    authorized_args = %{authorized_args | identifiers: identifiers}

    {:ok, authorized_args}
  end

  def authorize(request = %{role: role, user: user}, "delete_user")
      when role in ["developer", "administrator"] do
    authorized_args = from_access_request(request, :delete)

    id = authorized_args[:identifiers][:id] || user.id
    identifiers = %{authorized_args[:identifiers] | id: id}
    opts = Map.put(authorized_args[:opts], :type, :managed)
    authorized_args = %{authorized_args | identifiers: identifiers, opts: opts}

    {:ok, authorized_args}
  end

  #
  # MARK: Other
  #
  # def authorize(request = %{role: nil}, endpoint) do
  #   request
  #   |> Service.put_vas_data()
  #   |> authorize(endpoint)
  # end

  def authorize(_, _) do
    {:error, :access_denied}
  end
end
