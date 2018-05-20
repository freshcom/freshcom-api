defmodule BlueJet.Crm.DefaultService do
  use BlueJet, :service

  alias Ecto.Multi
  alias BlueJet.Crm.{Customer, PointAccount, PointTransaction}

  @behaviour BlueJet.Crm.Service

  #
  # MARK: Customer
  #
  def list_customer(fields \\ %{}, opts) do
    list(Customer, fields, opts)
  end

  def count_customer(fields \\ %{}, opts) do
    count(Customer, fields, opts)
  end

  def create_customer(fields, opts) do
    account = extract_account(opts)

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
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)
    primary_identifiers = Map.take(identifiers, [:id, :code, :user_id, :status])

    Customer.Query.default()
    |> for_account(account.id)
    |> Repo.get_by(primary_identifiers)
    |> Customer.match_by(identifiers)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_customer(nil, _, _), do: {:error, :not_found}

  def update_customer(customer = %Customer{}, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

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

  def update_customer(identifiers, fields, opts) do
    get_customer(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_customer(fields, opts)
  end

  def delete_customer(nil, _), do: {:error, :not_found}

  def delete_customer(customer = %Customer{}, opts) do
    account = extract_account(opts)

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

  def delete_customer(identifiers, opts) do
    get_customer(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_customer(opts)
  end

  def delete_all_customer(opts) do
    delete_all(Customer, opts)
  end

  #
  # MARK: Point Account
  #
  def get_point_account(identifiers, opts) do
    get(PointAccount, identifiers, opts)
  end

  #
  # MARK: Point Transaction
  #
  def list_point_transaction(fields \\ %{}, opts) do
    list(PointTransaction, fields, opts)
  end

  def count_point_transaction(fields \\ %{}, opts) do
    count(PointTransaction, fields, opts)
  end

  def create_point_transaction(fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

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

  def get_point_transaction(identifiers, opts) do
    get(PointTransaction, identifiers, opts)
  end

  def update_point_transaction(nil, _, _), do: {:error, :not_found}

  def update_point_transaction(point_transaction = %{}, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

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

  def update_point_transaction(identifiers, fields, opts) do
    get_point_transaction(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_point_transaction(fields, opts)
  end

  def delete_point_transaction(nil, _), do: {:error, :not_found}
  def delete_point_transaction(%PointTransaction{ status: "committed", amount: amount }, _) when amount != 0, do: {:error, :not_found}

  def delete_point_transaction(point_transaction = %PointTransaction{}, opts) do
    delete(point_transaction, opts)
  end

  def delete_point_transaction(identifiers, opts) do
    get_point_transaction(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_point_transaction(opts)
  end
end