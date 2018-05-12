defmodule BlueJet.Fulfillment.DefaultService do
  use BlueJet, :service
  use BlueJet.EventEmitter, namespace: :fulfillment

  alias Ecto.Multi
  alias BlueJet.Fulfillment.{FulfillmentPackage, FulfillmentItem, ReturnPackage, ReturnItem, Unlock}

  @behaviour BlueJet.Fulfillment.Service

  #
  # MARK: Fulfillment Package
  #
  def list_fulfillment_package(fields \\ %{}, opts) do
    list(FulfillmentPackage, fields, opts)
  end

  def count_fulfillment_package(fields \\ %{}, opts) do
    count(FulfillmentPackage, fields, opts)
  end

  def create_fulfillment_package(fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

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
    get(FulfillmentPackage, identifiers, opts)
  end

  def delete_fulfillment_package(nil, _), do: {:error, :not_found}

  def delete_fulfillment_package(fulfillment_package = %FulfillmentPackage{}, opts) do
    account = extract_account(opts)

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

  def delete_fulfillment_package(identifiers, opts) do
    get_fulfillment_package(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_fulfillment_package(opts)
  end

  def delete_all_fulfillment_package(opts) do
    delete_all(FulfillmentPackage, opts)
  end

  #
  # MARK: Fulfillment Item
  #
  def list_fulfillment_item(fields \\ %{}, opts) do
    list(FulfillmentItem, fields, opts)
  end

  def count_fulfillment_item(fields \\ %{}, opts) do
    count(FulfillmentItem, fields, opts)
  end

  def create_fulfillment_item(fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

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

  def get_fulfillment_item(identifiers \\ %{}, opts) do
    get(FulfillmentItem, identifiers, opts)
  end

  def update_fulfillment_item(nil, _, _), do: {:error, :not_found}

  def update_fulfillment_item(fulfillment_item = %FulfillmentItem{}, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

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

  def update_fulfillment_item(identifiers, fields, opts) do
    get_fulfillment_item(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_fulfillment_item(fields, opts)
  end

  def delete_fulfillment_item(nil, _), do: {:error, :not_found}

  def delete_fulfillment_item(fulfillment_item = %FulfillmentItem{}, opts) do
    delete(fulfillment_item, opts)
  end

  def delete_fulfillment_item(identifiers, opts) do
    get_fulfillment_item(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_fulfillment_item(opts)
  end

  #
  # MARK: Return Package
  #
  def list_return_package(fields \\ %{}, opts) do
    list(ReturnPackage, fields, opts)
  end

  def count_return_package(fields \\ %{}, opts) do
    count(ReturnPackage, fields, opts)
  end

  def delete_all_return_package(opts) do
    delete_all(ReturnPackage, opts)
  end

  #
  # MARK: Return Item
  #
  def create_return_item(fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

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
    list(Unlock, fields, opts)
  end

  def count_unlock(fields, opts) do
    count(Unlock, fields, opts)
  end

  def create_unlock(fields, opts) do
    create(Unlock, fields, opts)
  end

  def get_unlock(identifiers, opts) do
    get(Unlock, identifiers, opts)
  end

  def delete_unlock(nil, _), do: {:error, :not_found}

  def delete_unlock(unlock = %Unlock{}, opts) do
    delete(unlock, opts)
  end

  def delete_unlock(identifiers, opts) do
    get_unlock(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_unlock(opts)
  end
end