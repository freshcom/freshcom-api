defmodule BlueJet.CRM do
  use BlueJet, :context

  alias Ecto.Changeset
  alias Ecto.Multi

  alias BlueJet.Identity

  alias BlueJet.CRM.Customer
  alias BlueJet.CRM.PointAccount
  alias BlueJet.CRM.PointTransaction

  def handle_event("billing.payment.before_create", %{ fields: fields, owner: %{ type: "Customer", id: customer_id } }) do
    customer = Repo.get!(Customer, customer_id)
    customer = Customer.preprocess(customer, payment_processor: "stripe")
    fields = Map.put(fields, "stripe_customer_id", customer.stripe_customer_id)

    {:ok, fields}
  end
  def handle_event("billing.payment.before_create", %{ fields: fields }), do: {:ok, fields}
  def handle_event(_, _) do
    {:ok, nil}
  end

  ####
  # Customer
  ####
  def list_customer(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "crm.list_customer") do
      do_list_customer(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_list_customer(request = %AccessRequest{ vas: %{ account_id: account_id }, pagination: pagination }) do
    query =
      Customer.Query.default()
      |> search([:first_name, :last_name, :other_name, :code, :email, :phone_number, :id], request.search, request.locale, account_id)
      |> filter_by(status: request.filter[:status], label: request.filter[:label], delivery_address_country_code: request.filter[:delivery_address_country_code])
      |> Customer.Query.for_account(account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Customer |> Customer.Query.for_account(account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    customers =
      Repo.all(query)
      |> Repo.preload(Customer.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        total_count: total_count,
        result_count: result_count,
      },
      data: customers
    }

    {:ok, response}
  end

  def create_customer(request) do
    with {:ok, request} <- preprocess_request(request, "crm.create_customer") do
      request
      |> do_create_customer()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_customer(request = %{ account: account }) do
    fields = Map.merge(request.fields, %{
      "account_id" => account.id,
      "role" => "customer"
    })

    statements =
      Multi.new()
      |> Multi.run(:user, fn(_) ->
          if fields["status"] == "registered" do
            case Identity.do_create_user(%AccessRequest{ account: account, fields: fields}) do
              {:ok, %{ data: user }} -> {:ok, user}
              other -> other
            end
          else
            {:ok, nil}
          end
         end)
      |> Multi.run(:changeset, fn(%{ user: user }) ->
          fields = if user do
            Map.merge(fields, %{ "user_id" => user.id })
          else
            fields
          end

          changeset = Customer.changeset(%Customer{}, fields)
          {:ok, changeset}
         end)
      |> Multi.run(:customer, fn(%{ changeset: changeset }) ->
          Repo.insert(changeset)
         end)
      |> Multi.run(:point_account, fn(%{ customer: customer }) ->
          changeset = PointAccount.changeset(%PointAccount{}, %{ customer_id: customer.id, account_id: customer.account_id })
          Repo.insert(changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ customer: customer }} ->
        customer = Repo.preload(customer, Customer.Query.preloads(request.preloads))
        {:ok, %AccessResponse{ data: customer }}
      {:error, :user, response, _} ->
        {:error, response}
      {:error, :customer, changeset, _} ->
        {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  def get_customer(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "crm.get_customer") do
      do_get_customer(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_get_customer(request = %AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    customer = Customer |> Customer.Query.for_account(vas[:account_id]) |> Repo.get(id)
    do_get_customer_response(customer, request)
  end
  def do_get_customer(request = %AccessRequest{ role: "guest", vas: vas, params: params = %{ "code" => code } }) when map_size(params) >= 2 do
    customer = Customer |> Customer.Query.for_account(vas[:account_id]) |> Repo.get_by(code: code, status: "guest")

    params = Map.drop(params, ["code"])
    if Customer.match?(customer, params) do
      do_get_customer_response(customer, request)
    else
      {:error, :not_found}
    end
  end
  def do_get_customer(%AccessRequest{ role: "guest" }), do: {:error, :not_found}
  def do_get_customer(request = %AccessRequest{ role: "customer", vas: %{ account_id: account_id, user_id: user_id } }) do
    customer = Customer |> Customer.Query.for_account(account_id) |> Repo.get_by(user_id: user_id)
    do_get_customer_response(customer, request)
  end
  def do_get_customer(%AccessRequest{ role: "customer" }), do: {:error, :not_found}
  def do_get_customer(request = %AccessRequest{ vas: vas, params: %{ "code" => code } }) do
    customer = Customer |> Customer.Query.for_account(vas[:account_id]) |> Repo.get_by(code: code)
    do_get_customer_response(customer, request)
  end
  def do_get_customer(_), do: {:error, :not_found}

  defp do_get_customer_response(nil, _) do
    {:error, :not_found}
  end
  defp do_get_customer_response(customer, request) do
    customer =
      customer
      |> Repo.preload(Customer.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    {:ok, %AccessResponse{ data: customer }}
  end

  def update_customer(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "crm.update_customer") do
      do_update_customer(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_update_customer(request = %AccessRequest{ role: role, vas: vas, params: %{ "id" => id } }) do
    customer_query = Customer |> Customer.Query.for_account(vas[:account_id])

    customer = case role do
      "guest" -> Repo.get_by(customer_query, id: id, status: "guest")
      "customer" -> Repo.get(customer_query, id) # TODO: only find the customer of the user
      _ -> Repo.get(customer_query, id)
    end

    statements =
      Multi.new()
      |> Multi.run(:user, fn(_) ->
          cond do
            customer.status == "guest" && request.fields["status"] == "registered" ->
              case Identity.create_user(%AccessRequest{ vas: vas, fields: request.fields}) do
                {:ok, %{ data: user }} -> {:ok, user}
                other -> other
              end
            true -> {:ok, nil}
          end
         end)
      |> Multi.run(:changeset, fn(%{ user: user }) ->
          fields = if user do
            Map.merge(request.fields, %{ "user_id" => user.id, "account_id" => vas[:account_id] })
          else
            request.fields
          end

          changeset = Customer.changeset(customer, fields)
          {:ok, changeset}
         end)
      |> Multi.run(:customer, fn(%{ changeset: changeset}) ->
          Repo.update(changeset)
         end)

    with %Customer{} <- customer,
         {:ok, %{ customer: customer }} <- Repo.transaction(statements)
    do
      customer =
        customer
        |> Repo.preload(Customer.Query.preloads(request.preloads))
        |> Customer.put_external_resources(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: customer }}
    else
      nil ->
        {:error, :not_found}
      {:error, :user, response, _} ->
        {:error, response}
      {:error, :customer, changeset, _} ->
        {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  def delete_customer(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "crm.delete_customer") do
      do_delete_customer(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_delete_customer(%AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    customer = Customer |> Customer.Query.for_account(vas[:account_id]) |> Repo.get(id)

    statements =
      Multi.new()
      |> Multi.run(:delete_user, fn(_) ->
          if customer.user_id do
            Identity.do_delete_user(%AccessRequest{ vas: vas, params: %{ user_id: customer.user_id } })
          else
            {:ok, nil}
          end
         end)
      |> Multi.delete(:deleted_customer, customer)

    if customer do
      {:ok, _} = Repo.transaction(statements)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end

  #
  # PointTransaction
  #
  def create_point_transaction(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "crm.create_point_transaction") do
      do_create_point_transaction(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_create_point_transaction(request = %AccessRequest{ role: "customer", vas: vas }) do
    customer = Repo.get_by(Customer, user_id: vas[:user_id])

    fields = Map.merge(request.fields, %{
      "account_id" => vas[:account_id],
      "customer_id" => customer.id,
      "status" => "pending"
    })
    changeset = PointTransaction.changeset(%PointTransaction{}, fields)

    with {:ok, point_transaction} <- Repo.insert(changeset) do
      point_transaction = Repo.preload(point_transaction, PointTransaction.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: point_transaction }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end
  def do_create_point_transaction(request = %AccessRequest{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = PointTransaction.changeset(%PointTransaction{}, fields)

    statements =
      Multi.new()
      |> Multi.insert(:point_transaction, changeset)
      |> Multi.run(:point_account, fn(%{ point_transaction: point_transaction }) ->
          case point_transaction.status do
            "committed" ->
              point_transaction = Repo.preload(point_transaction, :point_account)
              new_balance = point_transaction.point_account.balance + point_transaction.amount

              changeset = Changeset.change(point_transaction.point_account, %{ balance: new_balance })
              Repo.update(changeset)
            _ -> {:ok, nil}
          end
         end)

    case Repo.transaction(statements) do
      {:ok, %{ point_transaction: point_transaction }} ->
        point_transaction = Repo.preload(point_transaction, PointTransaction.Query.preloads(request.preloads))
        {:ok, %AccessResponse{ data: point_transaction }}
      {:error, :point_transaction, changeset, _} ->
        {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  def get_point_transaction(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "crm.get_point_transaction") do
      do_get_point_transaction(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_get_point_transaction(request = %AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    point_transaction = PointTransaction |> PointTransaction.Query.for_account(vas[:account_id]) |> Repo.get(id)

    if point_transaction do
      point_transaction =
        point_transaction
        |> Repo.preload(PointTransaction.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: point_transaction }}
    else
      {:error, :not_found}
    end
  end

  # TODO
  def update_point_transaction(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "crm.update_point_transaction") do
      do_update_point_transaction(%{ request | role: role })
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
  def do_update_point_transaction(%AccessRequest{ vas: vas, params: %{ "id" => id }, fields: %{ "status" => "committed" } }) do
    point_transaction = PointTransaction |> PointTransaction.Query.for_account(vas[:account_id]) |> Repo.get(id)

    with %PointTransaction{} <- point_transaction,
         {:ok, point_transaction} <- PointTransaction.commit(point_transaction)
    do
      {:ok, %AccessResponse{ data: point_transaction }}
    else
      nil -> {:error, :not_found}
      {:error, errors} -> {:error, %AccessResponse{ errors: errors }}
    end
  end
end
