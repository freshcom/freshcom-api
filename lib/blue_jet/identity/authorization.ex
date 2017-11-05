defmodule BlueJet.Identity.Authorization do

  alias BlueJet.Identity.AccountMembership

  @role_endpoints %{
    "anonymous" => [
      "identity.create_user"
    ],

    "guest" => [
      "identity.create_user"
    ],

    "customer" => [

    ],

    "support_personnel" => [

    ],

    "developer" => [

    ],

    "administrator" => [
      "identity.create_user"
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