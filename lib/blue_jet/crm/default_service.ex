defmodule BlueJet.Crm.DefaultService do
  use BlueJet, :service

  alias Ecto.Multi
  alias BlueJet.Crm.IdentityService
  alias BlueJet.Crm.{Customer, PointAccount, PointTransaction}

  @behaviour BlueJet.Crm.Service

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  defp put_account(opts) do
    Map.put(opts, :account, get_account(opts))
  end

  #
  # MARK: Customer
  #
  def list_customer(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Customer.Query.default()
    |> Customer.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Customer.Query.filter_by(filter)
    |> Customer.Query.for_account(account.id)
    |> Customer.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_customer(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Customer.Query.default()
    |> Customer.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Customer.Query.filter_by(filter)
    |> Customer.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_customer(fields, opts) do
    account = get_account(opts)

    changeset =
      %Customer{ account_id: account.id, account: account }
      |> Customer.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.run(:changeset, fn(_) ->
          Customer.preprocess(fields, changeset)
         end)
      |> Multi.run(:customer, fn(%{ changeset: changeset }) ->
          Repo.insert(changeset)
         end)
      |> Multi.run(:processed_customer, fn(%{ customer: customer, changeset: changeset }) ->
          Customer.process(customer, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ customer: customer }} ->
        {:ok, customer}

      {:error, _, changeset, _} ->
        {:error, changeset}

      other -> other
    end
  end

  def get_customer(identifiers, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)
    primary_identifiers = Map.take(identifiers, [:id, :code, :user_id, :status])

    Customer.Query.default()
    |> Customer.Query.for_account(account.id)
    |> Repo.get_by(primary_identifiers)
    |> Customer.match_by(identifiers)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_customer(nil, _, _), do: {:error, :not_found}

  def update_customer(customer = %Customer{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ customer | account: account }
      |> Customer.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.run(:changeset, fn(_) ->
          Customer.preprocess(fields, changeset)
         end)
      |> Multi.run(:customer, fn(%{ changeset: changeset }) ->
          Repo.update(changeset)
         end)
      |> Multi.run(:processed_customer, fn(%{ customer: customer, changeset: changeset }) ->
          if map_size(changeset.changes) > 0 do
            Customer.process(customer, changeset, opts)
          else
            {:ok, customer}
          end
         end)

    case Repo.transaction(statements) do
      {:ok, %{ customer: customer }} ->
        customer = preload(customer, preloads[:path], preloads[:opts])
        {:ok, customer}

      {:error, _, changeset, _} ->
        {:error, changeset}

      other -> other
    end
  end

  def update_customer(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Customer
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_customer(fields, opts)
  end

  def delete_customer(nil, _), do: {:error, :not_found}

  def delete_customer(customer = %Customer{}, opts) do
    account = get_account(opts)

    changeset =
      %{ customer | account: account }
      |> Customer.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:customer, changeset)
      |> Multi.run(:process, fn(%{ customer: customer }) ->
          Customer.process(customer, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ customer: customer }} ->
        {:ok, customer}

      {:error, _, changeset, _} ->
        {:error, changeset}

      other -> other
    end
  end

  def delete_customer(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Customer
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_customer(opts)
  end

  def delete_all_customer(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    customer_ids =
      Customer.Query.default()
      |> Customer.Query.for_account(account.id)
      |> Customer.Query.paginate(size: batch_size, number: 1)
      |> Customer.Query.id_only()
      |> Repo.all()

    Customer.Query.default()
    |> Customer.Query.filter_by(%{ id: customer_ids })
    |> Repo.delete_all()

    if length(customer_ids) === batch_size do
      delete_all_customer(opts)
    else
      :ok
    end
  end

  #
  # MARK: Point Account
  #
  def get_point_account(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    PointAccount.Query.default()
    |> PointAccount.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  #
  # MARK: Point Transaction
  #
  def list_point_transaction(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    PointTransaction.Query.default()
    |> PointTransaction.Query.filter_by(filter)
    |> PointTransaction.Query.for_account(account.id)
    |> PointTransaction.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_point_transaction(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    PointTransaction.Query.default()
    |> PointTransaction.Query.filter_by(filter)
    |> PointTransaction.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_point_transaction(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %PointTransaction{ account_id: account.id, account: account }
      |> PointTransaction.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:point_transaction, changeset)
      |> Multi.run(:processed_point_transaction, fn(%{ point_transaction: point_transaction }) ->
          PointTransaction.process(point_transaction, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_point_transaction: point_transaction }} ->
        point_transaction = preload(point_transaction, preloads[:path], preloads[:opts])
        {:ok, point_transaction}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def get_point_transaction(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)
    filter = Map.take(fields, [:id, :code])

    PointTransaction.Query.default()
    |> PointTransaction.Query.for_account(account.id)
    |> Repo.get_by(filter)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_point_transaction(nil, _, _), do: {:error, :not_found}

  def update_point_transaction(point_transaction = %{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ point_transaction | account: account }
      |> PointTransaction.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:point_transaction, changeset)
      |> Multi.run(:processed_point_transaction, fn(%{ point_transaction: point_transaction }) ->
          PointTransaction.process(point_transaction, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_point_transaction: point_transaction }} ->
        point_transaction = preload(point_transaction, preloads[:path], preloads[:opts])
        {:ok, point_transaction}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_point_transaction(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    PointTransaction
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_point_transaction(fields, opts)
  end

  def delete_point_transaction(nil, _), do: {:error, :not_found}
  def delete_point_transaction(%PointTransaction{ status: "committed" }, _), do: {:error, :not_found}

  def delete_point_transaction(point_transaction = %PointTransaction{}, opts) do
    account = get_account(opts)

    changeset =
      %{ point_transaction | account: account }
      |> PointTransaction.changeset(:delete)

    with {:ok, point_transaction} <- Repo.delete(changeset) do
      {:ok, point_transaction}
    else
      other -> other
    end
  end

  def delete_point_transaction(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    PointTransaction
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_point_transaction(opts)
  end
end