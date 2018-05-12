defmodule BlueJet.Balance.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.Balance.{IdentityService, CrmService}

  #
  # MARK: Settings
  #
  def authorize(request = %{ role: role }, "get_settings") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_settings") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  #
  # MARK: Card
  #
  def authorize(request = %{ role: role, account: account, user: user }, "list_card") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    filter = Map.merge(authorized_args[:filter], %{ owner_id: customer.id, owner_type: "Customer", status: "saved_by_owner" })

    authorized_args = %{ authorized_args | filter: filter, all_count_filter: filter }
    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_card") when role in ["support_specialist"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    if authorized_args[:filter][:owner_id] do
      filter = Map.merge(authorized_args[:filter], %{ status: "saved_by_owner" })
      authorized_args = %{ authorized_args | filter: filter, all_count_filter: filter }

      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role }, "list_card") when role in ["developer", "administrator"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    filter = Map.merge(authorized_args[:filter], %{ status: "saved_by_owner" })
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: %{ status: "saved_by_owner" } }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "update_card") when role in ["customer", "support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_card") when role in ["customer", "support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: Payment
  #
  def authorize(request = %{ role: role, account: account, user: user }, "list_payment") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    filter = Map.merge(authorized_args[:filter], %{ owner_id: customer.id, owner_type: "Customer" })
    all_count_filter = Map.take(filter, [:owner_id, :owner_type])

    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }
    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_payment") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(%{ role: "anonymous" }, "create_payment") do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "create_payment") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(%{ role: role }, "get_payment") when role in ["anonymous", "guest"] do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "get_payment") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_payment") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_payment") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: Refund
  #
  def authorize(request = %{ role: role }, "create_refund") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
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
