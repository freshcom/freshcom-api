defmodule BlueJet.Crm.Service do
  use BlueJet, :service

  alias Ecto.Multi
  alias BlueJet.Crm.IdentityService
  alias BlueJet.Utils
  alias BlueJet.Crm.{Customer, PointAccount, PointTransaction}

  @spec list_customer(map, map) :: [Customer.t()]
  def list_customer(query \\ %{}, opts), do: default_list(Customer, query, opts)

  @spec count_customer(map, map) :: integer
  def count_customer(query \\ %{}, opts), do: default_count(Customer, query, opts)

  @doc """
  Creates a customer.

  If the status of the customer is set to `"registered"` a user will also be created
  together with the customer. The created user will have role `"customer"`.
  """
  @spec create_customer(map, map) :: {:ok, Customer.t()} | {:error, %{errors: Keyword.t()}}
  def create_customer(fields, opts) do
    account = extract_account(opts)
    fields = if fields["username"], do: fields, else: Map.put(fields, "username", fields["email"])

    changeset =
      %Customer{account_id: account.id, account: account}
      |> Customer.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.run(:user, fn(_) -> create_user(fields, opts) end)
      |> Multi.run(:changeset, &put_user_id(changeset, &1[:user]))
      |> Multi.run(:customer, &Repo.insert(&1[:changeset]))
      |> Multi.run(:point_account, &create_point_account(&1[:customer]))

    case Repo.transaction(statements) do
      {:ok, %{customer: customer, point_account: point_account, user: user}} ->
        {:ok, %{customer | point_account: point_account, user: user}}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp create_user(%{"status" => "registered"} = fields, opts) do
    fields
    |> Map.put("role", "customer")
    |> IdentityService.create_user(opts)
  end

  defp create_user(_, _), do: {:ok, nil}

  defp create_point_account(customer) do
    point_account = Repo.insert!(%PointAccount{
      account_id: customer.account_id,
      customer_id: customer.id
    })

    {:ok, point_account}
  end

  defp put_user_id(changeset, user) do
    user_id = Map.get(user || %{}, :id)
    changeset = put_change(changeset, :user_id, user_id)

    {:ok, changeset}
  end

  @spec get_customer(map, map) :: Customer.t() | nil
  def get_customer(identifiers, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)
    primary_identifiers = Map.take(identifiers, [:id, :code, :email, :user_id, :status])

    Customer.Query.default()
    |> for_account(account.id)
    |> Repo.get_by(primary_identifiers)
    |> Customer.match_by(identifiers)
    |> preload(preload[:paths], preload[:opts])
  end

  @spec update_customer(map, map, map) ::
    {:ok, Customer.t()} | {:error, %{errors: Keyword.t()}} | {:error, :not_found}
  def update_customer(identifiers_or_customer, fields, opts)

  def update_customer(nil, _, _), do: {:error, :not_found}

  def update_customer(%Customer{} = customer, fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %{customer | account: account}
      |> Customer.changeset(:update, fields, opts[:locale])

    # We use changeset.changes instead of fields because we need to check whether
    # the status has been changed to "registered"
    user_fields = Utils.stringify_keys(changeset.changes)

    statements =
      Multi.new()
      |> Multi.run(:user, fn(_) -> create_user(user_fields, opts) end)
      |> Multi.run(:changeset, &put_user_id(changeset, &1[:user]))
      |> Multi.run(:customer, &Repo.update(&1[:changeset]))
      |> Multi.run(:_, &Customer.Proxy.sync_to_user(&1[:customer], opts))

    case Repo.transaction(statements) do
      {:ok, %{customer: customer}} ->
        {:ok, preload(customer, preload[:paths], preload[:opts])}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_customer(identifiers, fields, opts) do
    get_customer(identifiers, Map.put(opts, :preload, %{}))
    |> update_customer(fields, opts)
  end

  @spec delete_customer(map, map) ::
    {:ok, Customer.t()} | {:error, %{errors: Keyword.t()}} | {:error, :not_found}
  def delete_customer(identifiers_or_customer, opts)

  def delete_customer(nil, _), do: {:error, :not_found}

  def delete_customer(%Customer{} = customer, opts) do
    account = extract_account(opts)

    changeset =
      %{customer | account: account}
      |> Customer.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:customer, changeset)
      |> Multi.run(:_, fn(_) -> Customer.Proxy.delete_user(customer) end)

    case Repo.transaction(statements) do
      {:ok, %{customer: customer}} ->
        {:ok, customer}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_customer(identifiers, opts) do
    get_customer(identifiers, Map.put(opts, :preload, %{}))
    |> delete_customer(opts)
  end

  # No need to delete user when doing delete all customer because right now
  # this function is only called when account reset happens and when that
  # happens all user will already be deleted
  @spec delete_all_customer(map) :: :ok
  def delete_all_customer(opts), do: default_delete_all(Customer, opts)

  #
  # MARK: Point Account
  #
  @spec get_point_account(map, map) :: PointAccount.t() | nil
  def get_point_account(identifiers, opts), do: default_get(PointAccount, identifiers, opts)

  #
  # MARK: Point Transaction
  #
  @spec list_point_transaction(map, map) :: [PointTransaction.t()]
  def list_point_transaction(query \\ %{}, opts), do: default_list(PointTransaction, query, opts)

  @spec count_point_transaction(map, map) :: integer
  def count_point_transaction(query \\ %{}, opts), do: default_count(PointTransaction, query, opts)

  @spec create_point_transaction(map, map) :: {:ok, PointTransaction.t()} | {:error, %{errors: Keyword.t()}}
  def create_point_transaction(fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %PointTransaction{account_id: account.id, account: account}
      |> PointTransaction.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.run(:initial_point_account, fn(_) -> get_point_account_with_lock(changeset) end)
      |> Multi.run(:changeset, &put_balance_after_commit(changeset, &1[:initial_point_account]))
      |> Multi.run(:point_transaction, &Repo.insert(&1[:changeset]))
      |> Multi.run(:point_account, &sync_to_point_account(&1[:changeset], &1[:initial_point_account]))

    case Repo.transaction(statements) do
      {:ok, %{point_transaction: transaction}} ->
        {:ok, preload(transaction, preload[:paths], preload[:opts])}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp get_point_account_with_lock(%{valid?: true} = changeset) do
    point_account_id = get_field(changeset, :point_account_id)
    point_account =
      PointAccount
      |> PointAccount.Query.filter_by(%{id: point_account_id})
      |> lock_exclusively()
      |> Repo.one()

    {:ok, point_account}
  end

  defp get_point_account_with_lock(_), do: {:ok, nil}

  defp put_balance_after_commit(%{valid?: true, changes: %{status: "committed"}} = changeset, point_account) do
    amount = get_field(changeset, :amount)
    new_balance = point_account.balance + amount
    changeset = put_change(changeset, :balance_after_commit, new_balance)

    {:ok, changeset}
  end

  defp put_balance_after_commit(changeset, _), do: {:ok, changeset}

  defp sync_to_point_account(%{valid?: true, changes: %{status: "committed"}} = changeset, point_account) do
    new_balance = get_field(changeset, :balance_after_commit)

    point_account
    |> change(balance: new_balance)
    |> Repo.update()
  end

  defp sync_to_point_account(_, _), do: {:ok, nil}

  @spec get_point_transaction(map, map) :: PointTransaction.t() | nil
  def get_point_transaction(identifiers, opts), do: default_get(PointTransaction, identifiers, opts)

  @spec update_point_transaction(map, map, map) ::
    {:ok, PointTransaction.t()} | {:error, %{errors: Keyword.t()}} | {:error, :not_found}
  def update_point_transaction(identifiers_or_transaction, fields, opts)

  def update_point_transaction(nil, _, _), do: {:error, :not_found}

  def update_point_transaction(%PointTransaction{} = transaction, fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %{transaction | account: account}
      |> PointTransaction.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.run(:initial_point_account, fn(_) -> get_point_account_with_lock(changeset) end)
      |> Multi.run(:changeset, &put_balance_after_commit(changeset, &1[:initial_point_account]))
      |> Multi.run(:point_transaction, &Repo.update(&1[:changeset]))
      |> Multi.run(:point_account, &sync_to_point_account(&1[:changeset], &1[:initial_point_account]))

    case Repo.transaction(statements) do
      {:ok, %{point_transaction: transaction}} ->
        transaction = preload(transaction, preload[:paths], preload[:opts])
        {:ok, transaction}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_point_transaction(identifiers, fields, opts) do
    get_point_transaction(identifiers, Map.put(opts, :preload, %{}))
    |> update_point_transaction(fields, opts)
  end

  @spec delete_point_transaction(map, map) ::
    {:ok, PointTransaction.t()} | {:error, %{errors: Keyword.t()}} | {:error, :not_found}
  def delete_point_transaction(identifiers_or_transaction, opts)

  def delete_point_transaction(%PointTransaction{} = transaction, opts), do: default_delete(transaction, opts)

  def delete_point_transaction(identifiers, opts) do
    identifiers = Map.put(identifiers, :status, "pending")
    default_delete(identifiers, opts, &get_point_transaction/2)
  end
end
