defmodule BlueJet.Balance.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.Balance.{CrmService, IdentityService}

  def authorize(request = %{ role: role, account: account, user: user }, "list_payment") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    filter = Map.merge(request.filter, %{ owner_id: customer.id, owner_type: "Customer" })

    authorized_args = %{ authorized_args | filter: filter }
    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_payment") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ vas: vas, role: nil }, endpoint) do
    request
    |> IdentityService.put_vas_data()
    |> authorize(endpoint)
  end

  def authorize(_, _) do
    {:error, :access_denied}
  end
end
