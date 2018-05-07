defmodule BlueJet.Fulfillment.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.Fulfillment.{IdentityService, CrmService}

  #
  # MARK: Fulfillment Package
  #
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
      authorized_args = %{ authorized_args | all_count_filter: Map.take(authorized_args[:filter], [:order_id, :customer_id]) }
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role }, "list_fulfillment_package") when role in ["business_analyst", "distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "get_fulfillment_package") when role in ["customer", "support_specialist", "business_analyst", "distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "delete_fulfillment_package") when role in ["distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: Fulfillment Item
  #
  def authorize(request = %{ role: role }, "list_fulfillment_item") when role in ["customer", "support_specialist"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    if request.params["package_id"] do
      filter = Map.merge(authorized_args[:filter], %{ package_id: request.params["package_id"] })
      all_count_filter = Map.take(filter, [:package_id])
      authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role }, "list_fulfillment_item") when role in ["distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "create_fulfillment_item") when role in ["distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(request = %{ role: role }, "update_fulfillment_item") when role in ["distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  #
  # MARK: Return Package
  #
  def authorize(request = %{ role: role, account: account, user: user }, "list_return_package") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    filter = Map.merge(request.filter, %{ customer_id: customer.id })

    authorized_args = %{ authorized_args | filter: filter, all_count_filter: %{ customer_id: customer.id } }
    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_return_package") when role in ["support_specialist"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    if authorized_args[:filter][:order_id] || authorized_args[:filter][:customer_id] do
      authorized_args = %{ authorized_args | all_count_filter: Map.take(authorized_args[:filter], [:order_id, :customer_id]) }
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role }, "list_return_package") when role in ["business_analyst", "distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  #
  # MARK: Return Item
  #
  def authorize(request = %{ role: role }, "create_return_item") when role in ["distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  #
  # MARK: Unlock
  #
  def authorize(request = %{ role: role, account: account, user: user }, "list_unlock") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    filter = Map.merge(request.filter, %{ customer_id: customer.id })

    authorized_args = %{ authorized_args | filter: filter, all_count_filter: %{ customer_id: customer.id } }
    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_unlock") when role in ["support_specialist"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    if authorized_args[:filter][:customer_id] do
      authorized_args = %{ authorized_args | all_count_filter: Map.take(authorized_args[:filter], [:customer_id]) }
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role }, "list_unlock") when role in ["distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "create_unlock") when role in ["support_specialist", "distribution_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(%{ role: role }, "get_unlock") when role in ["anonymous", "guest"] do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "get_unlock") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "delete_unlock") when role in ["support_specialist", "distribution_specialist", "developer", "administrator"] do
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
