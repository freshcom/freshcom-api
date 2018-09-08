defmodule BlueJet.Goods.Policy do
  # use BlueJet, :policy

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
  # MARK: Stockable
  #
  def authorize(%{_role_: role}, :list_stockable) when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role} = req, :list_stockable) when not is_nil(role) do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_stockable) when role in ["inventory_specialist", "developer", "administrator"] do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role}, :get_stockable) when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role} = req, :get_stockable) when not is_nil(role) do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_stockable) when role in ["inventory_specialist", "developer", "administrator"] do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_stockable) when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Unlockable
  #
  def authorize(%{_role_: role}, :list_unlockable) when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role} = req, :list_unlockable) when not is_nil(role) do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_unlockable) when role in ["inventory_specialist", "developer", "administrator"] do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role}, :get_unlockable) when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role} = req, :get_unlockable) when not is_nil(role) do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_unlockable) when role in ["inventory_specialist", "developer", "administrator"] do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_unlockable) when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Depositable
  #
  def authorize(%{_role_: role}, :list_depositable) when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role} = req, :list_depositable) when not is_nil(role) do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_depositable) when role in ["inventory_specialist", "developer", "administrator"] do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role}, :get_depositable) when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(%{_role_: role} = req, :get_depositable) when not is_nil(role) do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_depositable) when role in ["inventory_specialist", "developer", "administrator"] do
    req = %{req | _preload_: %{paths: req.preloads, opts: %{}}}
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_depositable) when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
