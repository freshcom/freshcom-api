defmodule BlueJet.Crm.Service do
  use BlueJet, :service

  alias Ecto.Multi
  alias BlueJet.Crm.IdentityService
  alias BlueJet.Crm.{Customer, PointAccount, PointTransaction}

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  def get_point_account(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    PointAccount.Query.default()
    |> PointAccount.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
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

  def get_point_transaction(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    PointTransaction.Query.default()
    |> PointTransaction.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
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

  def get_customer(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(fields, account)

    preload_query = Customer.Query.preloads(preloads[:path], preloads[:filter])
    Customer.Query.default()
    |> Customer.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> Repo.preload(preload_query)
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