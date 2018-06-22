defmodule BlueJet.Crm.Policy do
  use BlueJet, :policy

  alias BlueJet.Crm.Service

  #
  # MARK: Customer
  #
  def authorize(request = %{role: role}, "list_customer")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :list)}
  end

  def authorize(request = %{role: role}, "create_customer") when role in ["guest"] do
    authorized_args = from_access_request(request, :create)

    fields = Map.merge(authorized_args[:fields], %{"status" => "registered"})
    authorized_args = %{authorized_args | fields: fields}

    {:ok, authorized_args}
  end

  def authorize(request = %{role: role}, "create_customer")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :create)}
  end

  def authorize(request = %{role: role}, "get_customer") when role in ["guest"] do
    authorized_args = from_access_request(request, :get)

    identifiers =
      authorized_args[:identifiers]
      |> Map.merge(atom_map(request.params))
      |> Map.drop([:id])

    authorized_args = %{authorized_args | identifiers: identifiers}

    {:ok, authorized_args}
  end

  def authorize(request = %{role: role}, "get_customer")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  def authorize(request = %{account: account, user: user, role: role}, "update_customer")
      when role in ["customer"] do
    authorized_args = from_access_request(request, :update)

    customer = Service.get_customer(%{user_id: user.id}, %{account: account})
    authorized_args = %{authorized_args | identifiers: %{id: customer.id}}

    {:ok, authorized_args}
  end

  def authorize(request = %{role: role}, "update_customer")
      when role in ["support_specialist", "developer", "administrator"] do
    authorized_args = from_access_request(request, :update)

    opts = Map.merge(authorized_args[:opts], %{bypass_user_pvc_validation: true})
    authorized_args = %{authorized_args | opts: opts}

    {:ok, authorized_args}
  end

  def authorize(request = %{role: role}, "delete_customer")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # Point Transaction
  #
  def authorize(request = %{account: account, user: user, role: role}, "list_point_transaction")
      when role in ["customer"] do
    authorized_args = from_access_request(request, :list)

    filter =
      Map.merge(authorized_args[:filter], %{
        point_account_id: request.params["point_account_id"],
        status: "committed"
      })

    customer = Service.get_customer(%{user_id: user.id}, %{account: account})

    point_account =
      Service.get_point_account(
        %{
          id: filter[:point_account_id],
          customer_id: customer.id
        },
        %{account: account}
      )

    if point_account do
      all_count_filter = Map.take(filter, [:status, :point_account_id])
      authorized_args = %{authorized_args | filter: filter, all_count_filter: all_count_filter}

      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{role: role}, "list_point_transaction")
      when role in ["support_specialist", "developer", "administrator"] do
    authorized_args = from_access_request(request, :list)

    filter =
      Map.merge(authorized_args[:filter], %{
        point_account_id: request.params["point_account_id"],
        status: "committed"
      })

    all_count_filter = Map.take(filter, [:status, :point_account_id])
    authorized_args = %{authorized_args | filter: filter, all_count_filter: all_count_filter}

    {:ok, authorized_args}
  end

  def authorize(request = %{account: account, user: user, role: role}, "create_point_transaction")
      when role in ["customer"] do
    authorized_args = from_access_request(request, :create)

    fields =
      Map.merge(authorized_args[:fields], %{
        "point_account_id" => request.params["point_account_id"],
        "status" => "pending"
      })

    customer = Service.get_customer(%{user_id: user.id}, %{account: account})

    point_account =
      Service.get_point_account(
        %{
          id: fields["point_account_id"],
          customer_id: customer.id
        },
        %{account: account}
      )

    if point_account do
      authorized_args = %{authorized_args | fields: fields}
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{role: role}, "create_point_transaction")
      when role in ["support_specialist", "developer", "administrator"] do
    authorized_args = from_access_request(request, :create)

    fields =
      Map.merge(authorized_args[:fields], %{
        "point_account_id" => request.params["point_account_id"]
      })

    authorized_args = %{authorized_args | fields: fields}

    {:ok, authorized_args}
  end

  def authorize(request = %{role: role}, "get_point_transaction")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  def authorize(request = %{role: role}, "update_point_transaction")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(request = %{account: account, user: user, role: role}, "delete_point_transaction")
      when role in ["customer"] do
    authorized_args = from_access_request(request, :delete)

    customer = Service.get_customer(%{user_id: user.id}, %{account: account})

    point_transaction =
      Service.get_point_transaction(%{id: authorized_args[:id]}, %{account: account})

    point_account =
      Service.get_point_account(
        %{
          id: point_transaction.point_account_id,
          customer_id: customer.id
        },
        %{account: account}
      )

    if point_account do
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{role: role}, "delete_point_transaction")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end

  defp atom_map(m) do
    for {key, val} <- m, into: %{}, do: {String.to_atom(key), val}
  end
end
