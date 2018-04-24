defmodule BlueJet.Fulfillment.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.Fulfillment.{IdentityService, CrmService}

  def authorize(request = %{ role: role, account: account, user: user }, "list_fulfillment_package") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    filter = Map.merge(request.filter, %{ customer_id: customer.id })

    authorized_args = %{ authorized_args | filter: filter, all_count_filter: %{ customer_id: customer.id } }
    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_fulfillment_package") when role in ["support_specialist"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    if authorized_args[:filter][:order_id] || authorized_args[:filter][:customer_id] do
      %{ authorized_args | all_count_filter: Map.take(authorized_args[:filter], [:order_id, :customer_id]) }
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role }, "list_fulfillment_package") when role in ["business_analyst", "distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "get_fulfillment_package") when role in ["customer", "support_specialist", "business_analyst", "distribution_specialist", "distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: nil }, endpoint) do
    request
    |> IdentityService.put_vas_data()
    |> authorize(endpoint)
  end

  def authorize(_, _) do
    {:error, :access_denied}
  end
end
