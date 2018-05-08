defmodule BlueJet.Fulfillment.DefaultService do
  use BlueJet, :service
  use BlueJet.EventEmitter, namespace: :fulfillment

  alias Ecto.Multi
  alias BlueJet.Fulfillment.IdentityService
  alias BlueJet.Fulfillment.{FulfillmentPackage, FulfillmentItem, ReturnPackage, ReturnItem, Unlock}

  @behaviour BlueJet.Fulfillment.Service

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
  # MARK: Fulfillment Package
  #
  def list_fulfillment_package(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    FulfillmentPackage.Query.default()
    |> FulfillmentPackage.Query.filter_by(filter)
    |> FulfillmentPackage.Query.for_account(account.id)
    |> FulfillmentPackage.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> FulfillmentPackage.Query.order_by([desc: :updated_at])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_fulfillment_package(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    FulfillmentPackage.Query.default()
    |> FulfillmentPackage.Query.filter_by(filter)
    |> FulfillmentPackage.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_fulfillment_package(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %FulfillmentPackage{ account_id: account.id, account: account, system_label: opts[:system_label] }
      |> FulfillmentPackage.changeset(:insert, fields)

    with {:ok, fulfillment_package} <- Repo.insert(changeset) do
      fulfillment_package = preload(fulfillment_package, preloads[:path], preloads[:opts])
      {:ok, fulfillment_package}
    else
      other -> other
    end
  end

  def get_fulfillment_package(identifiers, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    FulfillmentPackage.Query.default()
    |> FulfillmentPackage.Query.for_account(account.id)
    |> Repo.get_by(identifiers)
    |> preload(preloads[:path], preloads[:opts])
  end

  def delete_fulfillment_package(nil, _), do: {:error, :not_found}

  def delete_fulfillment_package(fulfillment_package = %FulfillmentPackage{}, opts) do
    account = get_account(opts)

    changeset =
      %{ fulfillment_package | account: account }
      |> FulfillmentPackage.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:fulfillment_package, changeset)
      |> Multi.run(:after_delete, fn(%{ fulfillment_package: fulfillment_package}) ->
          emit_event("fulfillment.fulfillment_package.delete.success", %{ fulfillment_package: fulfillment_package, changeset: changeset })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ fulfillment_package: fulfillment_package }} ->
        {:ok, fulfillment_package}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_fulfillment_package(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    FulfillmentPackage
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_fulfillment_package(opts)
  end

  def delete_all_fulfillment_package(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    fulfillment_package_ids =
      FulfillmentPackage.Query.default()
      |> FulfillmentPackage.Query.for_account(account.id)
      |> FulfillmentPackage.Query.paginate(size: batch_size, number: 1)
      |> FulfillmentPackage.Query.id_only()
      |> Repo.all()

    FulfillmentPackage.Query.default()
    |> FulfillmentPackage.Query.filter_by(%{ id: fulfillment_package_ids })
    |> Repo.delete_all()

    if length(fulfillment_package_ids) === batch_size do
      delete_all_fulfillment_package(opts)
    else
      :ok
    end
  end

  #
  # MARK: Fulfillment Item
  #
  def list_fulfillment_item(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    FulfillmentItem.Query.default()
    |> FulfillmentItem.Query.filter_by(filter)
    |> FulfillmentItem.Query.for_account(account.id)
    |> FulfillmentItem.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_fulfillment_item(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    FulfillmentItem.Query.default()
    |> FulfillmentItem.Query.filter_by(filter)
    |> FulfillmentItem.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_fulfillment_item(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %FulfillmentItem{ account_id: account.id, account: account, package: opts[:package] }
      |> FulfillmentItem.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.run(:changeset, fn(_) ->
          FulfillmentItem.preprocess(changeset)
         end)
      |> Multi.run(:fulfillment_item, fn(%{ changeset: changeset}) ->
          Repo.insert(changeset)
         end)
      |> Multi.run(:processed_fulfillment_item, fn(%{ fulfillment_item: fulfillment_item, changeset: changeset }) ->
          FulfillmentItem.process(fulfillment_item, changeset)
         end)
      |> Multi.run(:after_create, fn(%{ fulfillment_item: fulfillment_item }) ->
          emit_event("fulfillment.fulfillment_item.create.success", %{ fulfillment_item: fulfillment_item })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ fulfillment_item: fulfillment_item }} ->
        fulfillment_item = preload(fulfillment_item, preloads[:path], preloads[:opts])
        {:ok, fulfillment_item}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_fulfillment_item(nil, _, _), do: {:error, :not_found}

  def update_fulfillment_item(fulfillment_item = %FulfillmentItem{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ fulfillment_item | account: account }
      |> FulfillmentItem.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.run(:changeset, fn(_) ->
          FulfillmentItem.preprocess(changeset)
         end)
      |> Multi.run(:fulfillment_item, fn(%{ changeset: changeset }) ->
          Repo.update(changeset)
         end)
      |> Multi.run(:processed_fulfillment_item, fn(%{ fulfillment_item: fulfillment_item, changeset: changeset }) ->
          FulfillmentItem.process(fulfillment_item, changeset)
         end)
      |> Multi.run(:after_update, fn(%{ fulfillment_item: fulfillment_item }) ->
          emit_event("fulfillment.fulfillment_item.update.success", %{ fulfillment_item: fulfillment_item, changeset: changeset })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ fulfillment_item: fulfillment_item }} ->
        fulfillment_item = preload(fulfillment_item, preloads[:path], preloads[:opts])
        {:ok, fulfillment_item}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_fulfillment_item(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    FulfillmentItem
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_fulfillment_item(fields, opts)
  end

  def delete_fulfillment_item(nil, _), do: {:error, :not_found}

  def delete_fulfillment_item(fulfillment_item = %FulfillmentItem{}, opts) do
    account = get_account(opts)

    changeset =
      %{ fulfillment_item | account: account }
      |> FulfillmentItem.changeset(:delete)

    with {:ok, fulfillment_item} <- Repo.delete(changeset) do
      {:ok, fulfillment_item}
    else
      other -> other
    end
  end

  def delete_fulfillment_item(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    FulfillmentItem
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_fulfillment_item(opts)
  end

  #
  # MARK: Return Package
  #
  def list_return_package(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    ReturnPackage.Query.default()
    |> ReturnPackage.Query.filter_by(filter)
    |> ReturnPackage.Query.for_account(account.id)
    |> ReturnPackage.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_return_package(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    ReturnPackage.Query.default()
    |> ReturnPackage.Query.filter_by(filter)
    |> ReturnPackage.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def delete_all_return_package(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    return_package_ids =
      ReturnPackage.Query.default()
      |> ReturnPackage.Query.for_account(account.id)
      |> ReturnPackage.Query.paginate(size: batch_size, number: 1)
      |> ReturnPackage.Query.id_only()
      |> Repo.all()

    ReturnPackage.Query.default()
    |> ReturnPackage.Query.filter_by(%{ id: return_package_ids })
    |> Repo.delete_all()

    if length(return_package_ids) === batch_size do
      delete_all_return_package(opts)
    else
      :ok
    end
  end

  #
  # MARK: Return Item
  #
  def create_return_item(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %ReturnItem{ account_id: account.id, account: account, package: opts[:package] || %ReturnItem{}.package  }
      |> ReturnItem.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.run(:changeset, fn(_) ->
          ReturnItem.preprocess(changeset)
         end)
      |> Multi.run(:return_item, fn(%{ changeset: changeset}) ->
          Repo.insert(changeset)
         end)
      |> Multi.run(:processed_return_item, fn(%{ return_item: return_item, changeset: changeset }) ->
          ReturnItem.process(return_item, changeset)
         end)
      |> Multi.run(:after_create, fn(%{ return_item: return_item }) ->
          emit_event("fulfillment.return_item.create.success", %{ return_item: return_item, changeset: changeset })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ return_item: return_item }} ->
        return_item = preload(return_item, preloads[:path], preloads[:opts])
        {:ok, return_item}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
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