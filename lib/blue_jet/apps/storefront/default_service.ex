defmodule BlueJet.Storefront.DefaultService do
  use BlueJet, :service
  use BlueJet.EventEmitter, namespace: :storefront

  alias Ecto.{Multi, Changeset}
  alias BlueJet.Storefront.{Order, OrderLineItem}

  @behaviour BlueJet.Storefront.Service

  #
  # MARK: Order
  #
  def list_order(fields \\ %{ sort: [desc: :opened_at] }, opts) do
    list(Order, fields, opts)
  end

  def count_order(fields \\ %{}, opts) do
    count(Order, fields, opts)
  end

  def create_order(fields, opts) do
    create(Order, fields, opts)
  end

  def get_order(identifiers, opts) do
    get(Order, identifiers, opts)
  end

  def update_order(nil, _, _), do: {:error, :not_found}

  def update_order(order = %Order{}, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

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

  def update_order(identifiers, fields, opts) do
    get_order(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_order(fields, opts)
  end

  def delete_order(nil, _), do: {:error, :not_found}

  def delete_order(order = %Order{}, opts) do
    delete(order, opts)
  end

  def delete_order(identifiers, opts) do
    get_order(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_order(opts)
  end

  def delete_all_order(opts)  do
    delete_all(Order, opts)
  end

  #
  # MARK: Order Line Item
  #
  def create_order_line_item(fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

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

  def get_order_line_item(identifiers, opts) do
    get(OrderLineItem, identifiers, opts)
  end

  def update_order_line_item(nil, _, _), do: {:error, :not_found}

  def update_order_line_item(oli = %OrderLineItem{}, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

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

  def update_order_line_item(identifiers, fields, opts) do
    get_order_line_item(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_order_line_item(fields, opts)
  end

  def delete_order_line_item(nil, _), do: {:error, :not_found}

  def delete_order_line_item(oli = %OrderLineItem{}, opts) do
    account = extract_account(opts)

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

  def delete_order_line_item(identifiers, opts) do
    get_order_line_item(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_order_line_item(opts)
  end
end