defmodule BlueJet.Identity.Authorization do

  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Repo

  @role_endpoints %{
    "anonymous" => [
      "identity.create_user",
      "identity.get_account"
    ],

    "guest" => [
      "identity.create_user",
      "identity.get_account"
    ],

    "customer" => [
      "identity.get_account",
      "identity.get_user"
    ],

    "support_personnel" => [
      "identity.get_account",
      "identity.get_user"
    ],

    "developer" => [
      "identity.get_account",
      "identity.get_user"
    ],

    "administrator" => [
      "identity.create_user",
      "identity.get_account",
      "identity.get_user"
    ],
  }

  def authorize(vas, endpoint) when map_size(vas) == 0 do
    authorize("anonymous", endpoint)
  end
  def authorize(%{ account_id: account_id, user_id: user_id }, endpoint) do
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