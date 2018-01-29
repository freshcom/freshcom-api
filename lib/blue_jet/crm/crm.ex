defmodule BlueJet.Crm do
  use BlueJet, :context

  alias Ecto.Multi

  alias BlueJet.Identity

  alias BlueJet.Crm.{Customer, PointAccount, PointTransaction}
  alias BlueJet.Crm.IdentityService

  defmodule Service do
    def get_point_account(customer_id, opts) do
      account_id = opts[:account_id] || opts[:account].id

      Repo.get_by(PointAccount, customer_id: customer_id, account_id: account_id)
    end

    def create_point_transaction(fields, opts) do
      account_id = opts[:account_id] || opts[:account].id

      changeset =
        %PointTransaction{ account_id: account_id, account: opts[:account] }
        |> PointTransaction.changeset(fields)

      statements =
        Multi.new()
        |> Multi.insert(:point_transaction, changeset)
        |> Multi.run(:processed_point_transaction, fn(%{ point_transaction: point_transaction }) ->
            PointTransaction.process(point_transaction, changeset)
           end)

      case Repo.transaction(statements) do
        {:ok, %{ processed_point_transaction: point_transaction }} -> {:ok, point_transaction}

        {:error, _, changeset, _} -> {:error, changeset}
      end
    end

    def get_point_transaction(id) do
      Repo.get(PointTransaction, id)
    end

    def update_point_transaction(point_transaction = %{}, fields, opts) do
      changeset =
        point_transaction
        |> Map.put(:account, opts[:account])
        |> PointTransaction.changeset(fields, opts[:locale])

      statements =
        Multi.new()
        |> Multi.update(:point_transaction, changeset)
        |> Multi.run(:processed_point_transaction, fn(%{ point_transaction: point_transaction }) ->
            PointTransaction.process(point_transaction, changeset)
           end)

      case Repo.transaction(statements) do
        {:ok, %{ processed_point_transaction: point_transaction }} -> {:ok, point_transaction}

        {:error, _, changeset, _} -> {:error, changeset}
      end
    end

    def update_point_transaction(id, fields, opts) do
      account_id = opts[:account_id] || opts[:account].id

      point_transaction =
        PointTransaction.Query.default()
        |> PointTransaction.Query.for_account(account_id)
        |> Repo.get(id)

      if point_transaction do
        update_point_transaction(point_transaction, fields, opts)
      else
        {:error, :not_found}
      end
    end

    def get_customer(id) do
      Repo.get(Customer, id)
    end

    def get_customer(id, opts) do
      account_id = opts[:account_id] || opts[:account].id
      Repo.get_by(Customer, id: id, account_id: account_id)
    end

    def get_customer_by_user_id(user_id, opts) do
      account_id = opts[:account_id] || opts[:account].id
      Repo.get_by(Customer, user_id: user_id, account_id: account_id)
    end

    def get_customer_by_code(code, opts) do
      account_id = opts[:account_id] || opts[:account].id
      Repo.get_by(Customer, code: code, account_id: account_id)
    end

    def create_customer(fields, opts) do
      account_id = opts[:account_id] || opts[:account].id
      statements =
        Multi.new()
        |> Multi.run(:user, fn(_) ->
            if fields["status"] == "registered" do
              IdentityService.create_user(fields, %{ account_id: account_id })
            else
              {:ok, nil}
            end
           end)
        |> Multi.run(:changeset, fn(%{ user: user }) ->
            customer = %Customer{ account_id: account_id, account: opts[:account] }
            customer = if user do
              %{ customer | user_id: user.id }
            else
              customer
            end

            changeset = Customer.changeset(customer, fields)
            {:ok, changeset}
           end)
        |> Multi.run(:customer, fn(%{ changeset: changeset }) ->
            Repo.insert(changeset)
           end)
        |> Multi.run(:point_account, fn(%{ customer: customer }) ->
            Repo.insert(%PointAccount{ account_id: customer.account.id, customer_id: customer.id })
           end)

      case Repo.transaction(statements) do
        {:ok, %{ customer: customer }} ->
          {:ok, customer}

        {:error, _, changeset, _} ->
          {:error, changeset}

        other -> other
      end
    end

    def update_customer(customer = %{}, fields, opts) do
      account_id = opts[:account_id] || opts[:account].id

      statements =
        Multi.new()
        |> Multi.run(:user, fn(_) ->
            cond do
              customer.status == "guest" && fields["status"] == "registered" ->
                fields = Map.merge(fields, %{ "role" => "customer" })
                IdentityService.create_user(fields, %{ account_id: account_id })

              true ->
                {:ok, nil}
            end
           end)
        |> Multi.run(:changeset, fn(%{ user: user }) ->
            fields = if user do
              Map.merge(fields, %{ "user_id" => user.id, "account_id" => account_id })
            else
              fields
            end

            changeset =
              customer
              |> Map.put(:account, opts[:account])
              |> Customer.changeset(fields, opts[:locale])

            {:ok, changeset}
           end)
        |> Multi.run(:customer, fn(%{ changeset: changeset}) ->
            Repo.update(changeset)
           end)

      case Repo.transaction(statements) do
        {:ok, %{ customer: customer }} ->
          {:ok, customer}

        {:error, _, changeset, _} ->
          {:error, changeset}

        other -> other
      end
    end

    def update_customer(id, fields, opts) do
      customer = Repo.get(Customer, id)

      if customer do
        update_customer(customer, fields, opts)
      else
        {:error, :not_found}
      end
    end
  end

  defmodule EventHandler do
    @behaviour BlueJet.EventHandler

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
      |> search([:name, :code, :email, :phone_number, :id], request.search, request.locale, account.default_locale, Customer.translatable_fields)
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
    fields = Map.merge(request.fields, %{
      "role" => "customer"
    })

    case Service.create_customer(fields, %{ account: account }) do
      {:ok, customer} ->
        customer_response(customer, request)

      {:error, changeset} ->
        {:error, %AccessResponse{ errors: changeset.errors }}
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

    with %Customer{} <- customer,
         {:ok, customer} <- Service.update_customer(customer, request.fields, %{ account: account, locale: request.locale })
    do
      customer_response(customer, request)
    else
      nil ->
        {:error, :not_found}

      {:error, changeset} ->
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
  # Point Account
  #
  defp point_account_response(nil, _), do: {:error, :not_found}

  defp point_account_response(point_account, request = %{ account: account }) do
    preloads = PointAccount.Query.preloads(request.preloads, role: request.role)

    point_account =
      point_account
      |> Repo.preload(preloads)
      |> PointAccount.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: point_account }}
  end
  def do_get_point_account(request = %{ account: account, params: %{ "customer_id" => customer_id } }) do
    point_account =
      PointAccount.Query.default()
      |> PointAccount.Query.for_customer(customer_id)
      |> PointAccount.Query.for_account(account.id)
      |> Repo.one()

    point_account_response(point_account, request)
  end

  #
  # PointTransaction
  #
  def list_point_transaction(request) do
    with {:ok, request} <- preprocess_request(request, "crm.list_point_transaction") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_point_transaction()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  # TODO: check role, customer can only view its own point transaction
  def do_list_point_transaction(request = %{
    account: account,
    pagination: pagination,
    params: %{ "point_account_id" => point_account_id }
  }) do
    data_query =
      PointTransaction.Query.default()
      |> PointTransaction.Query.for_point_account(point_account_id)
      |> PointTransaction.Query.committed()
      |> PointTransaction.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)

    preloads = PointTransaction.Query.preloads(request.preloads, role: request.role)
    point_transactions =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> PointTransaction.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: total_count,
        total_count: total_count,
      },
      data: point_transactions
    }

    {:ok, response}
  end

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

  def do_create_point_transaction(request = %{ role: "customer", account: account, params: %{ "point_account_id" => point_account_id } }) do
    request = %{ request | locale: account.default_locale }

    fields = Map.merge(request.fields, %{
      "point_account_id" => point_account_id,
      "status" => "pending"
    })
    point_transaction = %PointTransaction{ account_id: account.id, account: account }
    changeset = PointTransaction.changeset(point_transaction, fields)

    with {:ok, point_transaction} <- Repo.insert(changeset) do
      point_transaction_response(point_transaction, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def do_create_point_transaction(request = %{ account: account, params: %{ "point_account_id" => point_account_id } }) do
    request = %{ request | locale: account.default_locale }

    fields = Map.merge(request.fields, %{ "point_account_id" => point_account_id })
    point_transaction = %PointTransaction{ account_id: account.id, account: account }
    changeset = PointTransaction.changeset(point_transaction, fields)

    statements =
      Multi.new()
      |> Multi.insert(:point_transaction, changeset)
      |> Multi.run(:processed_point_transaction, fn(%{ point_transaction: point_transaction }) ->
          PointTransaction.process(point_transaction, changeset)
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

  def update_point_transaction(request) do
    with {:ok, request} <- preprocess_request(request, "crm.update_point_transaction") do
      request
      |> do_update_point_transaction
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_point_transaction(request = %{ account: account, params: %{ "id" => id } }) do
    with {:ok, pt} <- Service.update_point_transaction(id, request.fields, %{ account: account }) do
      point_transaction_response(pt, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_point_transaction(request) do
    with {:ok, request} <- preprocess_request(request, "crm.delete_point_transaction") do
      request
      |> do_delete_point_transaction()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_point_transaction(%{ account: account, params: %{ "id" => id } }) do
    point_transaction =
      PointTransaction.Query.default()
      |> PointTransaction.Query.for_account(account.id)
      |> Repo.get(id)

    if point_transaction.amount == 0 do
      Repo.delete!(point_transaction)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end
end
