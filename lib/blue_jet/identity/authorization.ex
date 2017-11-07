defmodule BlueJet.Identity.Authorization do

  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Repo

  @role_endpoints %{
    "anonymous" => [
      "identity.create_user"
    ],

    "guest" => [
      "identity.create_user",
      "identity.get_account"
    ],

    "customer" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user"
    ],

    "support_specialist" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user",

      "identity.list_sku",
      "identity.get_sku"
    ],

    "inventory_specialist" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user",

      "inventory.list_sku",
      "inventory.create_sku",
      "inventory.get_sku",
      "inventory.update_sku",
      "inventory.delete_sku",
      "inventory.list_unlockable",
      "inventory.create_unlockable",
      "inventory.get_unlockable",
      "inventory.update_unlockable",
      "inventory.delete_unlockable"
    ],

    "developer" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user",

      "inventory.list_sku",
      "inventory.create_sku",
      "inventory.get_sku",
      "inventory.update_sku",
      "inventory.delete_sku",
      "inventory.list_unlockable",
      "inventory.create_unlockable",
      "inventory.get_unlockable",
      "inventory.update_unlockable",
      "inventory.delete_unlockable"
    ],

    "administrator" => [
      "identity.list_account",
      "identity.get_account",
      "identity.update_account",
      "identity.create_user",
      "identity.get_user",

      "inventory.list_sku",
      "inventory.create_sku",
      "inventory.get_sku",
      "inventory.update_sku",
      "inventory.delete_sku",
      "inventory.list_unlockable",
      "inventory.create_unlockable",
      "inventory.get_unlockable",
      "inventory.update_unlockable",
      "inventory.delete_unlockable"
    ]
  }

  def authorize(vas, endpoint) when map_size(vas) == 0 do
    authorize("anonymous", endpoint)
  end
  def authorize(%{ user_id: user_id, account_id: account_id }, endpoint) do
    with %AccountMembership{ role: role } <- Repo.get_by(AccountMembership, account_id: account_id, user_id: user_id),
         {:ok, role} <- authorize(role, endpoint)
    do
      {:ok, role}
    else
      nil -> {:error, :no_membership}
      {:error, role} -> {:error, :role_not_allowed}
    end
  end
  def authorize(%{ account_id: account_id }, endpoint) do
    authorize("guest", endpoint)
  end
  def authorize(role, target_endpoint) when is_bitstring(role) do
    endpoints = Map.get(@role_endpoints, role)
    found = Enum.any?(endpoints, fn(endpoint) -> endpoint == target_endpoint end)

    if found do
      {:ok, role}
    else
      {:error, role}
    end
  end

end