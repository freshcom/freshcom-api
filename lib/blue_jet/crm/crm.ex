defmodule BlueJet.CRM do
  use BlueJet, :context

  alias Ecto.Changeset
  alias Ecto.Multi

  alias BlueJet.Identity

  alias BlueJet.CRM.Customer
  alias BlueJet.CRM.PointAccount
  alias BlueJet.CRM.PointTransaction

  defmodule Shortcut do
    alias BlueJet.CRM

    def get_account(%{ account_id: account_id, account: nil }) do
      response = CRM.get_account(%AccessRequest{
        vas: %{ account_id: account_id }
      })

      case response do
        {:ok, %{ data: account }} -> account

        _ -> nil
      end
    end

    def get_account(%{ account: account }), do: account
  end

  def handle_event("balance.payment.before_create", %{ fields: fields, owner: %{ type: "Customer", id: customer_id } }) do
    customer = Repo.get!(Customer, customer_id)
    customer = Customer.preprocess(customer, payment_processor: "stripe")
    fields = Map.put(fields, "stripe_customer_id", customer.stripe_customer_id)

    {:ok, fields}
  end
  def handle_event("balance.payment.before_create", %{ fields: fields }), do: {:ok, fields}
  def handle_event(_, _) do
    {:ok, nil}
  end

  ####
  # Customer
  ####
  def list_customer(request) do
    with {:ok, request} <- preprocess_request(request, "crm.list_customer") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_customer()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_customer(request = %{ account: account, filter: filter, counts: counts, pagination: pagination }) do
    data_query =
      Customer.Query.default()
      |> search([:first_name, :last_name, :other_name, :code, :email, :phone_number, :id], request.search, request.locale, account.default_locale)
      |> filter_by(status: filter[:status], label: filter[:label], delivery_address_country_code: filter[:delivery_address_country_code])
      |> Customer.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      Customer.Query.default()
      |> filter_by(status: counts[:all][:status])
      |> Customer.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    preloads = Customer.Query.preloads(request.preloads, role: request.role)
    customers =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> Customer.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count,
      },
      data: customers
    }

    {:ok, response}
  end

  defp customer_response(nil, _), do: {:error, :not_found}

  defp customer_response(customer, request = %{ account: account }) do
    preloads = Customer.Query.preloads(request.preloads, role: request.role)

    customer =
      customer
      |> Repo.preload(preloads)
      |> Customer.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: customer }}
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
    request = %{ request | locale: account.default_locale }

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
          customer = if user do
            %Customer{ user_id: user.id }
          else
            %Customer{}
          end

          changeset = Customer.changeset(customer, fields, request.locale, account.default_locale)
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
        customer_response(customer, request)

      {:error, :user, response, _} ->
        {:error, response}

      {:error, :customer, changeset, _} ->
        {:error, %AccessResponse{ errors: changeset.errors }}

      other -> other
    end
  end

  def get_customer(request) do
    with {:ok, request} <- preprocess_request(request, "crm.get_customer") do
      request
      |> do_get_customer()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_customer(request = %{ role: "guest", account: account, params: params = %{ "code" => code } }) when map_size(params) >= 2 do
    customer =
      Customer
      |> Customer.Query.for_account(account.id)
      |> Repo.get_by(code: code, status: "guest")

    params = Map.drop(params, ["code"])
    if Customer.match?(customer, params) do
      customer_response(customer, request)
    else
      {:error, :not_found}
    end
  end

  def do_get_customer(%{ role: "guest" }), do: {:error, :not_found}

  def do_get_customer(request = %{ role: "customer", account: account, vas: %{ user_id: user_id } }) do
    customer =
      Customer
      |> Customer.Query.for_account(account.id)
      |> Repo.get_by(user_id: user_id)

    customer_response(customer, request)
  end

  def do_get_customer(%{ role: "customer" }), do: {:error, :not_found}

  def do_get_customer(request = %{ account: account, params: %{ "id" => id } }) do
    customer =
      Customer.Query.default()
      |> Customer.Query.for_account(account.id)
      |> Repo.get(id)

    customer_response(customer, request)
  end

  def do_get_customer(request = %{ account: account, params: %{ "code" => code } }) do
    customer =
      Customer.Query.default()
      |> Customer.Query.for_account(account.id)
      |> Repo.get_by(code: code)

    customer_response(customer, request)
  end

  def do_get_customer(_), do: {:error, :not_found}

  def update_customer(request) do
    with {:ok, request} <- preprocess_request(request, "crm.update_customer") do
      request
      |> do_update_customer()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_customer(request = %{ role: role, account: account, vas: vas, params: %{ "id" => id } }) do
    customer_query =
      Customer.Query.default()
      |> Customer.Query.for_account(account.id)

    customer = cond do
      role == "guest" -> Repo.get_by(customer_query, id: id, status: "guest")
      role == "customer" && vas[:user_id] -> Repo.get_by(customer_query, id: id, user_id: vas[:user_id]) # TODO: only find the customer of the user
      true -> Repo.get(customer_query, id)
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

          changeset = Customer.changeset(customer, fields, request.locale, account.default_locale)
          {:ok, changeset}
         end)
      |> Multi.run(:customer, fn(%{ changeset: changeset}) ->
          Repo.update(changeset)
         end)

    with %Customer{} <- customer,
         {:ok, %{ customer: customer }} <- Repo.transaction(statements)
    do
      customer_response(customer, request)
    else
      nil ->
        {:error, :not_found}

      {:error, :user, response, _} ->
        {:error, response}

      {:error, :customer, changeset, _} ->
        {:error, %AccessResponse{ errors: changeset.errors }}

      other -> other
    end
  end

  def delete_customer(request) do
    with {:ok, request} <- preprocess_request(request, "crm.delete_customer") do
      request
      |> do_delete_customer()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_customer(%{ account: account, params: %{ "id" => id } }) do
    customer =
      Customer.Query.default()
      |> Customer.Query.for_account(account.id)
      |> Repo.get(id)

    statements =
      Multi.new()
      |> Multi.run(:delete_user, fn(_) ->
          if customer.user_id do
            Identity.do_delete_user(%AccessRequest{ account: account, params: %{ "id" => customer.user_id } })
          else
            {:ok, nil}
          end
         end)
      |> Multi.run(:deleted_customer, fn(_) ->
          Repo.delete!(customer)
          {:ok, customer}
         end)

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
  defp point_transaction_response(nil, _), do: {:error, :not_found}

  defp point_transaction_response(point_transaction, request = %{ account: account }) do
    preloads = PointTransaction.Query.preloads(request.preloads, role: request.role)

    point_transaction =
      point_transaction
      |> Repo.preload(preloads)
      |> PointTransaction.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: point_transaction }}
  end

  def create_point_transaction(request) do
    with {:ok, request} <- preprocess_request(request, "crm.create_point_transaction") do
      request
      |> do_create_point_transaction()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_point_transaction(request = %{ role: "customer", account: account, vas: vas }) do
    request = %{ request | locale: account.default_locale }
    customer = Repo.get_by(Customer, user_id: vas[:user_id])

    fields = Map.merge(request.fields, %{
      "account_id" => account.id,
      "customer_id" => customer.id,
      "status" => "pending"
    })
    changeset = PointTransaction.changeset(%PointTransaction{}, fields)

    with {:ok, point_transaction} <- Repo.insert(changeset) do
      point_transaction_response(point_transaction, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def do_create_point_transaction(request = %{ account: account }) do
    request = %{ request | locale: account.default_locale }

    fields = Map.merge(request.fields, %{ "account_id" => account.id })
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
        point_transaction_response(point_transaction, request)

      {:error, :point_transaction, changeset, _} ->
        {:error, %AccessResponse{ errors: changeset.errors }}

      other -> other
    end
  end

  def get_point_transaction(request) do
    with {:ok, request} <- preprocess_request(request, "crm.get_point_transaction") do
      request
      |> do_get_point_transaction()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_point_transaction(request = %{ account: account, params: %{ "id" => id } }) do
    point_transaction =
      PointTransaction.Query.default()
      |> PointTransaction.Query.for_account(account.id)
      |> Repo.get(id)

    point_transaction_response(point_transaction, request)
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
