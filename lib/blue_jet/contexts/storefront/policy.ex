defmodule BlueJet.Storefront.Policy do
  use BlueJet, :policy

  alias BlueJet.Storefront.Service
  alias BlueJet.Storefront.CrmService

  #
  # MARK: Order
  #
  def authorize(request = %{ role: role, account: account, user: user }, "list_order") when role in ["customer"] do
    authorized_args = from_access_request(request, :list)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    filter = Map.merge(request.filter, %{ customer_id: customer.id, status: ["opened", "closed"] })
    all_count_filter = Map.take(filter, [:customer_id, :status])

    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }
    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_order") when role in ["support_specialist", "business_analyst", "developer", "administrator"] do
    authorized_args = from_access_request(request, :list)
    filter = if !authorized_args.filter[:status] do
      Map.merge(authorized_args.filter, %{ status: ["opened", "closed"] })
    else
      authorized_args.filter
    end

    all_count_filter = Map.take(filter, [:status])
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role, account: account, user: user }, "create_order") when role in ["customer"] do
    authorized_args = from_access_request(request, :create)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    fields = Map.merge(authorized_args.fields, %{ customer_id: customer.id })
    authorized_args = %{ authorized_args | fields: fields }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "create_order") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :create)}
  end

  def authorize(request = %{ role: role }, "get_order") when role in ["guest"] do
    authorized_args = from_access_request(request, :get)

    identifiers = Map.merge(authorized_args.identifiers, %{ status: "cart", customer_id: nil })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role, account: account, user: user }, "get_order") when role in ["customer"] do
    authorized_args = from_access_request(request, :get)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    identifiers = Map.merge(authorized_args.identifiers, %{ customer_id: customer.id })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "get_order") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_order") when role in ["guest"] do
    authorized_args = from_access_request(request, :update)
    fields = authorized_args.fields

    fields = if fields[:status] != "opened" do
      Map.drop(fields, [:status])
    else
      fields
    end

    identifiers = Map.merge(authorized_args.identifiers, %{ status: "cart", customer_id: nil })
    authorized_args = %{ authorized_args | identifiers: identifiers, fields: fields }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role, account: account, user: user }, "update_order") when role in ["customer"] do
    request = %{ request | role: "guest" }
    {:ok, authorized_args} = authorize(request, "update_order")

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    identifiers = Map.merge(authorized_args.identifiers, %{ customer_id: customer.id })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "update_order") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_order") when role in ["guest"] do
    authorized_args = from_access_request(request, :delete)

    identifiers = Map.merge(authorized_args.identifiers, %{ status: "cart", customer_id: nil })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role, account: account, user: user }, "delete_order") when role in ["customer"] do
    authorized_args = from_access_request(request, :delete)

    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    identifiers = Map.merge(authorized_args.identifiers, %{ status: "cart", customer_id: customer.id })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "delete_order") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: Order Line Item
  #
  def authorize(request = %{ role: role, account: account }, "create_order_line_item") when role in ["guest"] do
    authorized_args = from_access_request(request, :create)

    order = Service.get_order(%{
      id: authorized_args.fields["order_id"],
      customer_id: nil,
      status: "cart",
    }, %{ account: account })

    if order do
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role, account: account, user: user }, "create_order_line_item") when role in ["customer"] do
    authorized_args = from_access_request(request, :create)
    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    order = Service.get_order(%{
      id: authorized_args.fields["order_id"],
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
    {:ok, from_access_request(request, :create)}
  end

  def authorize(request = %{ role: role, account: account }, "update_order_line_item") when role in ["guest"] do
    authorized_args = from_access_request(request, :update)

    oli = Service.get_order_line_item(authorized_args.identifiers, %{ account: account })
    order = Service.get_order(%{
      id: oli.order_id,
      status: "cart",
      customer_id: nil
    }, %{ account: account })

    if order do
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role, account: account, user: user }, "update_order_line_item") when role in ["customer"] do
    authorized_args = from_access_request(request, :update)

    oli = Service.get_order_line_item(authorized_args.identifiers, %{ account: account })
    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    order = Service.get_order(%{
      id: oli.order_id,
      status: "cart",
      customer_id: customer.id
    }, %{ account: account })

    if order do
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role }, "update_order_line_item") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(request = %{ role: role, account: account }, "delete_order_line_item") when role in ["guest"] do
    authorized_args = from_access_request(request, :delete)

    oli = Service.get_order_line_item(authorized_args.identifiers, %{ account: account })
    order = Service.get_order(%{
      id: oli.order_id,
      status: "cart",
      customer_id: nil
    }, %{ account: account })

    if order do
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role, account: account, user: user }, "delete_order_line_item") when role in ["customer"] do
    authorized_args = from_access_request(request, :delete)

    oli = Service.get_order_line_item(authorized_args.identifiers, %{ account: account })
    customer = CrmService.get_customer(%{ user_id: user.id }, %{ account: account })
    order = Service.get_order(%{
      id: oli.order_id,
      status: "cart",
      customer_id: customer.id
    }, %{ account: account })

    if order do
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: role }, "delete_order_line_item") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
