defmodule BlueJet.Storefront.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.Storefront.Service
  alias BlueJet.Storefront.{IdentityService, CrmService}

  #
  # MARK: Order
  #
  def authorize(request = %{ role: role, account: account, user: user }, "list_order") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    filter = Map.merge(request.filter, %{ customer_id: customer.id, status: ["opened", "closed"] })
    all_count_filter = Map.take(filter, [:customer_id, :status])

    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }
    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_order") when role in ["support_specialist", "business_analyst", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role, account: account, user: user }, "create_order") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :create)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    fields = Map.merge(authorized_args[:fields], %{ customer_id: customer.id })
    authorized_args = %{ authorized_args | fields: fields }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "create_order") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(request = %{ role: role }, "get_order") when role in ["guest"] do
    authorized_args = AccessRequest.to_authorized_args(request, :get)

    identifiers = Map.merge(authorized_args[:identifiers], %{ status: "cart" })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role, account: account, user: user }, "get_order") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :get)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    identifiers = Map.merge(authorized_args[:identifiers], %{ customer_id: customer.id })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "get_order") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_order") when role in ["guest"] do
    authorized_args = AccessRequest.to_authorized_args(request, :update)
    fields = authorized_args[:fields]

    fields = if fields[:status] != "opened" do
      Map.drop(fields, [:status])
    else
      fields
    end

    identifiers = Map.merge(authorized_args[:identifiers], %{ status: "cart" })
    authorized_args = %{ authorized_args | identifiers: identifiers, fields: fields }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role, account: account, user: user }, "update_order") when role in ["customer"] do
    request = %{ request | role: "guest" }
    {:ok, authorized_args} = authorize(request, "update_order")

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    identifiers = Map.merge(authorized_args[:identifiers], %{ customer_id: customer.id })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "update_order") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_order") when role in ["guest"] do
    authorized_args = AccessRequest.to_authorized_args(request, :delete)

    identifiers = Map.merge(authorized_args[:identifiers], %{ status: "cart" })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role, account: account, user: user }, "delete_order") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :delete)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    identifiers = Map.merge(authorized_args[:identifiers], %{ status: "cart", customer_id: customer.id })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "delete_order") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: Order Line Item
  #
  def authorize(request = %{ role: role, account: account }, "create_order_line_item") when role in ["guest"] do
    authorized_args = AccessRequest.to_authorized_args(request, :create)

    order = Service.get_order(%{
      id: authorized_args[:fields]["order_id"],
      status: "cart",
    }, %{ account: account })

    if order do
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role, account: account, user: user }, "create_order_line_item") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :create)
    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    order = Service.get_order(%{
      id: authorized_args[:fields]["order_id"],
      status: "cart",
      customer_id: customer.id
    }, %{ account: account })

    if order do
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role }, "create_order_line_item") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(%{ role: role }, "update_order_line_item") when role in ["anonymous"] do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "update_order_line_item") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(%{ role: role }, "delete_order_line_item") when role in ["anonymous"] do
    {:error, :access_denied}
  end

  def authorize(request = %{ role: role }, "delete_order_line_item") when not is_nil(role) do
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
