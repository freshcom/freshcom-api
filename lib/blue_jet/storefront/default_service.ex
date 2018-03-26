defmodule BlueJet.Storefront.DefaultService do
  use BlueJet, :service
  use BlueJet.EventEmitter, namespace: :storefront

  alias BlueJet.Storefront.IdentityService
  alias BlueJet.Storefront.{Order, OrderLineItem}

  alias Ecto.Multi
  alias Ecto.Changeset

  @behaviour BlueJet.Storefront.Service

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  defp put_account(opts) do
    %{ opts | account: get_account(opts) }
  end

  #
  # MARK: Order
  #
  def list_order(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Order.Query.default()
    |> Order.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Order.Query.filter_by(filter)
    |> Order.Query.for_account(account.id)
    |> Order.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Order.Query.order_by([desc: :opened_at])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_order(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Order.Query.default()
    |> Order.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Order.Query.filter_by(filter)
    |> Order.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_order(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Order{ account_id: account.id, account: account }
      |> Order.changeset(:insert, fields)

    with {:ok, order} <- Repo.insert(changeset) do
      order = preload(order, preloads[:path], preloads[:opts])
      {:ok, order}
    else
      other -> other
    end
  end

  def get_order(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Order.Query.default()
    |> Order.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_order(nil, _, _), do: {:error, :not_found}

  def update_order(order = %Order{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ order | account: account }
      |> Order.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:order, changeset)
      |> Multi.run(:processed_order, fn(%{ order: order}) ->
          Order.process(order, changeset)
         end)
      |> Multi.run(:after_update, fn(%{ processed_order: order }) ->
          emit_event("storefront.order.update.success", %{ order: order, changeset: changeset, account: account })

          if Changeset.get_change(changeset, :status) == "opened" do
            root_line_items =
              OrderLineItem.Query.default()
              |> OrderLineItem.Query.for_order(order.id)
              |> OrderLineItem.Query.root()
              |> OrderLineItem.Query.order_by([desc: :sort_index, asc: :inserted_at])
              |> Repo.all()

            order = %{ order | root_line_items: root_line_items }
            emit_event("storefront.order.opened.success", %{ order: order, account: account })
          else
            {:ok, order}
          end
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_order: order }} ->
        order = preload(order, preloads[:path], preloads[:opts])
        {:ok, order}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_order(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Order
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_order(fields, opts)
  end

  def delete_order(nil, _), do: {:error, :not_found}

  def delete_order(order = %Order{}, opts) do
    account = get_account(opts)

    changeset =
      %{ order | account: account }
      |> Order.changeset(:delete)

    with {:ok, order} <- Repo.delete(changeset) do
      {:ok, order}
    else
      other -> other
    end
  end

  def delete_order(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Order
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_order(opts)
  end

  def delete_all_order(opts = %{ account: account = %{ mode: "test" }})  do
    batch_size = opts[:batch_size] || 1000

    order_ids =
      Order.Query.default()
      |> Order.Query.for_account(account.id)
      |> Order.Query.paginate(size: batch_size, number: 1)
      |> Order.Query.id_only()
      |> Repo.all()

    Order.Query.default()
    |> Order.Query.filter_by(%{ id: order_ids })
    |> Repo.delete_all()

    if length(order_ids) === batch_size do
      delete_all_order(opts)
    else
      :ok
    end
  end

  #
  # MARK: Order Line Item
  #
  def create_order_line_item(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %OrderLineItem{ account_id: account.id, account: account }
      |> OrderLineItem.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:oli, changeset)
      |> Multi.run(:processed_oli, fn(%{ oli: oli }) ->
          OrderLineItem.process(oli, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_oli: oli }} ->
        oli = preload(oli, preloads[:path], preloads[:opts])
        {:ok, oli}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_order_line_item(nil, _, _), do: {:error, :not_found}

  def update_order_line_item(oli = %OrderLineItem{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ oli | account: account }
      |> OrderLineItem.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:oli, changeset)
      |> Multi.run(:processed_oli, fn(%{ oli: oli }) ->
          OrderLineItem.process(oli, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_oli: oli }} ->
        oli = preload(oli, preloads[:path], preloads[:opts])
        {:ok, oli}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_order_line_item(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    OrderLineItem
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_order_line_item(fields, opts)
  end

  def delete_order_line_item(nil, _), do: {:error, :not_found}

  def delete_order_line_item(oli = %OrderLineItem{}, opts) do
    account = get_account(opts)

    changeset =
      %{ oli | account: account }
      |> OrderLineItem.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:oli, changeset)
      |> Multi.run(:processed_oli, fn(%{ oli: oli }) ->
          OrderLineItem.process(oli, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_oli: oli }} ->
        {:ok, oli}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_order_line_item(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    OrderLineItem
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_order_line_item(opts)
  end
end