defmodule BlueJet.Crm.Policy do
  use BlueJet, :policy

  alias BlueJet.Crm.Service

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
  # MARK: Customer
  #
  def authorize(%{_role_: role} = req, :list_customer)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_customer) when role in ["guest"] do
    req = if Enum.member?(["guest", "registered"], req.fields["status"]) do
      req
    else
      ContextRequest.put(req, :fields, "status", "registered")
    end

    req = ContextRequest.put(req, :_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_customer)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_customer) when role in ["guest"] do
    req =
      req
      |> ContextRequest.put(:_preload_, :paths, req.preloads)
      |> ContextRequest.drop(:identifiers, [:id])

    if (req.identifiers[:code] || req.identifiers[:email]) && map_size(req.identifiers) >= 3 do
      {:ok, req}
    else
      {:error, :access_denied}
    end
  end

  def authorize(%{_role_: role} = req, :get_customer) when role in ["customer"] do
    req =
      req
      |> ContextRequest.put(:identifiers, %{user_id: req._vad_[:user].id})
      |> ContextRequest.put(:_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_customer)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_customer)
      when role in ["customer"] do
    req =
      req
      |> ContextRequest.put(:identifiers, %{user_id: req._vad_[:user].id})
      |> ContextRequest.put(:_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_customer)
      when role in ["support_specialist", "developer", "administrator"] do
    req =
      req
      |> ContextRequest.put(:_opts_, :bypass_user_pvc_validation, true)
      |> ContextRequest.put(:_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_customer)
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  #
  # Point Transaction
  #
  def authorize(%{_role_: role, filter: %{point_account_id: pa_id}} = req, :list_point_transaction)
      when role in ["customer"] do
    identifiers = %{user_id: req._vad_[:user].id}
    opts = %{account: req._vad_[:account]}
    customer = Service.get_customer(identifiers, opts)

    identifiers = %{id: pa_id, customer_id: customer.id}
    opts = %{account: req._vad_[:account]}
    point_account = Service.get_point_account(identifiers, opts)

    if point_account do
      req = ContextRequest.put(req, :filter, :status, "committed")
      req =
        req
        |> ContextRequest.put(:_scope_, Map.take(req.filter, [:status, :point_account_id]))
        |> ContextRequest.put(:_preload_, :paths, req.preloads)

      {:ok, req}
    else
      {:error, :access_denied}
    end
  end

  def authorize(%{_role_: role} = req, :list_point_transaction)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :filter, :status, "committed")
    req =
      req
      |> ContextRequest.put(:_scope_, Map.take(req.filter, [:status, :point_account_id]))
      |> ContextRequest.put(:_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role, fields: %{"point_account_id" => pa_id}} = req, :create_point_transaction)
      when role in ["customer"] do
    identifiers = %{user_id: req._vad_[:user].id}
    opts = %{account: req._vad_[:account]}
    customer = Service.get_customer(identifiers, opts)

    identifiers = %{id: pa_id, customer_id: customer.id}
    opts = %{account: req._vad_[:account]}
    point_account = Service.get_point_account(identifiers, opts)

    if point_account do
      req =
        req
        |> ContextRequest.put(:fields, "status", "pending")
        |> ContextRequest.put(:_preload_, :paths, req.preloads)

      {:ok, req}
    else
      {:error, :access_denied}
    end
  end

  def authorize(%{_role_: role} = req, :create_point_transaction)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_point_transaction)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_point_transaction)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_preload_, :paths, req.preloads)

    {:ok, req}
  end

  def authorize(%{_role_: role, identifiers: %{id: transaction_id}} = req, :delete_point_transaction)
      when role in ["customer"] do
    identifiers = %{user_id: req._vad_[:user].id}
    opts = %{account: req._vad_[:account]}
    customer = Service.get_customer(identifiers, opts)

    identifiers = %{id: transaction_id}
    opts = %{account: req._vad_[:account]}
    transaction = Service.get_point_transaction(identifiers, opts)

    identifiers = %{id: transaction.point_account_id, customer_id: customer.id}
    opts = %{account: req._vad_[:account]}
    point_account = Service.get_point_account(identifiers, opts)

    if point_account do
      req = ContextRequest.put(req, :identifiers, "status", "pending")

      {:ok, req}
    else
      {:error, :access_denied}
    end
  end

  def authorize(%{_role_: role} = req, :delete_point_transaction)
      when role in ["support_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :identifiers, "status", "pending")

    {:ok, req}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
