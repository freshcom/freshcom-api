defmodule BlueJet.Goods.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.Goods.IdentityService

  #
  # MARK: Stockable
  #
  def authorize(%{ role: role }, "list_stockable") when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "list_stockable") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "create_stockable") when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(%{ role: role }, "get_stockable") when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "get_stockable") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_stockable") when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_stockable") when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: Unlockable
  #
  def authorize(%{ role: role }, "list_unlockable") when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "list_unlockable") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "create_unlockable") when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(%{ role: role }, "get_unlockable") when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "get_unlockable") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_unlockable") when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_unlockable") when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: Depositable
  #
  def authorize(%{ role: role }, "list_depositable") when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "list_depositable") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "create_depositable") when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(%{ role: role }, "get_depositable") when role in ["anonymous", "guest", "customer"] do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "get_depositable") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_depositable") when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_depositable") when role in ["inventory_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: Other
  #
  def authorize(request = %{ role: nil }, endpoint) do
    request
    |> IdentityService.put_vas_data()
    |> authorize(endpoint)
  end

  def authorize(_, _) do
    {:error, :access_denied}
  end
end
