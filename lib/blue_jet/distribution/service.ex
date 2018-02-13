defmodule BlueJet.Distribution.Service do
  use BlueJet, :service
  use BlueJet.EventEmitter, namespace: :distribution

  alias Ecto.Multi
  alias BlueJet.Distribution.IdentityService
  alias BlueJet.Distribution.{Fulfillment, FulfillmentLineItem, Unlock}

  @callback list_unlock(map, map) :: list
  @callback count_unlock(map, map) :: integer
  @callback create_unlock(map, map) :: {:ok, Unlock.t} | {:error, any}
  @callback get_unlock(map, map) :: Unlock.t | nil
  @callback delete_unlock(Unlock.t | String.t, map) :: {:ok, Unlock.t} | {:error, any}

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  defp get_account_id(opts) do
    opts[:account_id] || get_account(opts).id
  end

  defp put_account(opts) do
    %{ opts | account: get_account(opts) }
  end

  #
  # MARK: Fulfillment
  #
  def create_fulfillment(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Fulfillment{ account_id: account.id, account: account }
      |> Fulfillment.changeset(:insert, fields)

    with {:ok, fulfillment} <- Repo.insert(changeset) do
      fulfillment = preload(fulfillment, preloads[:path], preloads[:opts])
      {:ok, fulfillment}
    else
      other -> other
    end
  end

  def list_fulfillment(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Fulfillment.Query.default()
    |> Fulfillment.Query.filter_by(filter)
    |> Fulfillment.Query.for_account(account.id)
    |> Fulfillment.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_fulfillment(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Fulfillment.Query.default()
    |> Fulfillment.Query.filter_by(filter)
    |> Fulfillment.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def delete_fulfillment(nil, _), do: {:error, :not_found}

  def delete_fulfillment(fulfillment = %Fulfillment{}, opts) do
    account = get_account(opts)

    changeset =
      %{ fulfillment | account: account }
      |> Fulfillment.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:fulfillment, changeset)
      |> Multi.run(:after_delete, fn(%{ fulfillment: fulfillment}) ->
          emit_event("distribution.fulfillment.after_delete", %{ fulfillment: fulfillment })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ fulfillment: fulfillment }} ->
        {:ok, fulfillment}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_fulfillment(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Fulfillment
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_fulfillment(opts)
  end

  #
  # MARK: Fulfillment Line Item
  #
  def list_fulfillment_line_item(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    FulfillmentLineItem.Query.default()
    |> FulfillmentLineItem.Query.filter_by(filter)
    |> FulfillmentLineItem.Query.for_account(account.id)
    |> FulfillmentLineItem.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_fulfillment_line_item(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    FulfillmentLineItem.Query.default()
    |> FulfillmentLineItem.Query.filter_by(filter)
    |> FulfillmentLineItem.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_fulfillment_line_item(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %FulfillmentLineItem{ account_id: account.id, account: account, fulfillment: opts[:fulfillment] }
      |> FulfillmentLineItem.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.run(:changeset, fn(_) ->
          FulfillmentLineItem.preprocess(changeset)
         end)
      |> Multi.run(:fli, fn(%{ changeset: changeset}) ->
          Repo.insert(changeset)
         end)
      |> Multi.run(:after_create, fn(%{ fli: fli }) ->
          emit_event("distribution.fulfillment_line_item.after_create", %{ fulfillment_line_item: fli })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ fli: fli }} ->
        fli = preload(fli, preloads[:path], preloads[:opts])
        {:ok, fli}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_fulfillment_line_item(nil, _, _), do: {:error, :not_found}

  def update_fulfillment_line_item(fli = %FulfillmentLineItem{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ fli | account: account }
      |> FulfillmentLineItem.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.run(:changeset, fn(_) ->
          FulfillmentLineItem.preprocess(changeset)
         end)
      |> Multi.run(:fli, fn(%{ changeset: changeset }) ->
          Repo.update(changeset)
         end)
      |> Multi.run(:after_update, fn(%{ fli: fli }) ->
          emit_event("distribution.fulfillment_line_item.after_update", %{ fulfillment_line_item: fli, changeset: changeset })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ fli: fli }} ->
        fli = preload(fli, preloads[:path], preloads[:opts])
        {:ok, fli}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_fulfillment_line_item(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    FulfillmentLineItem
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_fulfillment_line_item(fields, opts)
  end

  #
  # MARK: Unlock
  #
  def list_unlock(fields, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Unlock.Query.default()
    |> Unlock.Query.filter_by(filter)
    |> Unlock.Query.for_account(account.id)
    |> Unlock.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_unlock(fields, opts) do
    account_id = get_account_id(opts)
    filter = get_filter(fields)

    Unlock.Query.default()
    |> Unlock.Query.filter_by(filter)
    |> Unlock.Query.for_account(account_id)
    |> Repo.aggregate(:count, :id)
  end

  def create_unlock(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Unlock{ account_id: account.id, account: account }
      |> Unlock.changeset(:insert, fields)

    with {:ok, unlock} <- Repo.insert(changeset) do
      unlock = preload(unlock, preloads[:path], preloads[:opts])
      {:ok, unlock}
    else
      other -> other
    end
  end

  def get_unlock(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Unlock.Query.default()
    |> Unlock.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def delete_unlock(nil, _), do: {:error, :not_found}

  def delete_unlock(unlock = %Unlock{}, opts) do
    account = get_account(opts)

    changeset =
      %{ unlock | account: account }
      |> Unlock.changeset(:delete)

    with {:ok, unlock} <- Repo.delete(changeset) do
      {:ok, unlock}
    else
      other -> other
    end
  end

  def delete_unlock(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Unlock
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_unlock(opts)
  end
end