defmodule BlueJet.Balance.Policy do
  use BlueJet, :policy

  alias BlueJet.Balance.CRMService

  # TODO: Fix this
  def authorize(%{vas: vas, _role_: nil} = req, endpoint) do
    identity_service =
      Atom.to_string(__MODULE__)
      |> String.split(".")
      |> Enum.drop(-1)
      |> Enum.join(".")
      |> Module.concat(IdentityService)

    vad = identity_service.get_vad(vas)
    role = identity_service.get_role(vad)
    default_locale = if vad[:account], do: vad[:account].default_locale, else: nil

    req
    |> Map.put(:_vad_, vad)
    |> Map.put(:_role_, role)
    |> Map.put(:_default_locale_, default_locale)
    |> authorize(endpoint)
  end

  #
  # MARK: Settings
  #
  def authorize(%{_role_: role} = req, :get_settings)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_settings)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Card
  #
  def authorize(%{_role_: role} = req, :list_card) when role in ["customer"] do
    identifiers = %{user_id: req._vad_.user}
    opts = %{account: req._vad_.account}
    customer = CRMService.get_customer(identifiers, opts)

    req =
      req
      |> ContextRequest.put(:filter, :owner_id, customer.id)
      |> ContextRequest.put(:filter, :owner_type, "Customer")
      |> ContextRequest.put(:filter, :status, "saved_by_owner")
      |> ContextRequest.put(:_include_, :paths, req.include)

    scope = Map.take(req.filter, [:owner_id, :owner_type, :status])
    req = ContextRequest.put(req, :_scope_, scope)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :list_card) when role in ["support_specialist"] do
    if req.filter[:owner_id] && req.filter[:owner_type] do
      req =
        req
        |> ContextRequest.put(:filter, :status, "saved_by_owner")
        |> ContextRequest.put(:_include_, :paths, req.include)

      scope = Map.take(req.filter, [:owner_id, :owner_type, :status])
      req = ContextRequest.put(req, :_scope_, scope)

      {:ok, req}
    else
      {:error, :access_denied}
    end
  end

  def authorize(%{_role_: role} = req, :list_card) when role in ["developer", "administrator"] do
    req =
      req
      |> ContextRequest.put(:filter, :status, "saved_by_owner")
      |> ContextRequest.put(:_include_, :paths, req.include)

    scope = Map.take(req.filter, [:owner_id, :owner_type, :status])
    req = ContextRequest.put(req, :_scope_, scope)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_card) when role in ["customer"] do
    identifiers = %{user_id: req._vad_.user}
    opts = %{account: req._vad_.account}
    customer = CRMService.get_customer(identifiers, opts)

    req =
      req
      |> ContextRequest.put(:fields, "owner_id", customer.id)
      |> ContextRequest.put(:filter, "owner_type", "Customer")
      |> ContextRequest.put(:filter, "status", "saved_by_owner")
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_card)
      when role in ["support_specialist", "developer", "administrator"] do
    req =
      req
      |> ContextRequest.put(:fields, "status", "saved_by_owner")
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_card) when role in ["customer"] do
    identifiers = %{user_id: req._vad_.user}
    opts = %{account: req._vad_.account}
    customer = CRMService.get_customer(identifiers, opts)

    req =
      req
      |> ContextRequest.put(:identifiers, :owner_id, customer.id)
      |> ContextRequest.put(:identifiers, :owner_type, "Customer")
      |> ContextRequest.put(:identifiers, :status, "saved_by_owner")
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_card)
      when role in ["support_specialist", "developer", "administrator"] do
    req =
      req
      |> ContextRequest.put(:identifiers, :status, "saved_by_owner")
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_card)
      when role in ["customer", "support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_card)
      when role in ["customer", "support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)
    {:ok, req}
  end

  #
  # MARK: Payment
  #
  def authorize(%{_role_: role} = req, :list_payment) when role in ["customer"] do
    identifiers = %{user_id: req._vad_.user}
    opts = %{account: req._vad_.account}
    customer = CRMService.get_customer(identifiers, opts)

    req =
      req
      |> ContextRequest.put(:filter, :owner_id, customer.id)
      |> ContextRequest.put(:filter, :owner_type, "Customer")
      |> ContextRequest.put(:_include_, :paths, req.include)

    scope = Map.take(req.filter, [:owner_id, :owner_type])
    req = ContextRequest.put(req, :_scope_, scope)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :list_payment)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)
    {:ok, req}
  end

  def authorize(%{_role_: "anonymous"}, :create_payment) do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role} = req, :create_payment) when not is_nil(role) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)
    {:ok, req}
  end

  def authorize(%{_role_: role}, :get_payment) when role in ["anonymous", "guest"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role} = req, :get_payment) when not is_nil(role) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_payment)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_payment)
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Refund
  #
  def authorize(%{_role_: role} = req, :create_refund)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)
    {:ok, req}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
