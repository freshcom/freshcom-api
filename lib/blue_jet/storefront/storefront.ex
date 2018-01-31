defmodule BlueJet.Storefront do
  use BlueJet, :context

  alias Ecto.Changeset
  alias Ecto.Multi

  alias BlueJet.Storefront.{BalanceService, CrmService}
  alias BlueJet.Storefront.Service
  alias BlueJet.Storefront.{Order, OrderLineItem, Unlock}

  defmodule EventHandler do
    @behaviour BlueJet.EventHandler

    def handle_event("balance.payment.after_create", %{ payment: %{ target_type: "Order", target_id: order_id } }) do
      order = Repo.get!(Order, order_id)

      case order.status do
        "cart" ->
          changeset =
            order
            |> Order.refresh_payment_status()
            |> Changeset.change(status: "opened", opened_at: Ecto.DateTime.utc())

          changeset
          |> Repo.update!()
          |> Order.process(changeset)
        _ ->
          {:ok, Order.refresh_payment_status(order)}
      end
    end

    def handle_event("balance.payment.after_update", %{ payment: %{ target_type: "Order", target_id: order_id } }) do
      order =
        Repo.get!(Order, order_id)
        |> Order.refresh_payment_status()

      {:ok, order}
    end

    def handle_event("balance.refund.after_create", %{ refund: %{ target_type: "Order", target_id: order_id } }) do
      order =
        Repo.get!(Order, order_id)
        |> Order.refresh_payment_status()

      {:ok, order}
    end

    def handle_event("distribution.fulfillment_line_item.after_create", %{ fulfillment_line_item: fli = %{ source_type: "OrderLineItem" } }) do
      oli = Repo.get!(OrderLineItem, fli.source_id)
      OrderLineItem.refresh_fulfillment_status(oli)

      {:ok, fli}
    end

    def handle_event("distribution.fulfillment_line_item.after_update", %{
      fulfillment_line_item: fli = %{ source_type: "OrderLineItem" },
      changeset: %{ changes: %{ status: status } }
    }) do
      oli = Repo.get!(OrderLineItem, fli.source_id)
      OrderLineItem.refresh_fulfillment_status(oli)

      if oli.source_type == "Unlockable" && (status == "returned" || status == "discarded") do
        unlock = Repo.get_by(Unlock, source_id: oli.id, source_type: "OrderLineItem")
        if unlock do
          Repo.delete!(unlock)
        end
      end

      {:ok, fli}
    end

    def handle_event(_, _) do
      {:ok, nil}
    end
  end

  defp get_sopts(request) do
    %{
      account: request.account,
      pagination: request.pagination,
      preloads: %{ path: request.preloads },
      locale: request.locale
    }
  end

  ####
  # Order
  ####
  defp transform_order_request_by_role(request = %{ account: account, vas: vas, role: "customer" }) do
    customer = CrmService.get_customer_by_user_id(vas[:user_id], %{ account: account })
    %{ request | filter: Map.put(request.filter, :customer_id, customer.id ) }
  end

  defp transform_order_request_by_role(request), do: request

  def list_order(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.list_order") do
      request
      |> transform_order_request_by_role()
      |> do_list_order()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_order(request = %{ account: account, filter: filter, pagination: pagination }) do
    filter = if !filter[:status] do
      Map.put(filter, :status, "opened")
    else
      filter
    end

    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_order(%{ account: account })

    all_count =
      %{ filter: Map.take(filter, [:customer_id]) }
      |> Service.count_order(%{ account: account })

    orders =
      %{ filter: filter, search: request.search }
      |> Service.list_order(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count,
      },
      data: orders
    }

    {:ok, response}
  end

  defp order_response(nil, _), do: {:error, :not_found}

  defp order_response(order, request = %{ account: account }) do
    preloads = Order.Query.preloads(request.preloads, role: request.role)

    order =
      order
      |> Repo.preload(preloads)
      |> Order.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: order }}
  end

  def create_order(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.create_order") do
      request
      |> do_create_order()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_order(request = %{ account: account }) do
    with {:ok, order} <- Service.create_order(request.fields, get_sopts(request)) do
      order = Translation.translate(order, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: order }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_order(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.get_order") do
      request
      |> do_get_order()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_order(request = %{ account: account, params: %{ "id" => id } }) do
    order =
      %{ id: id }
      |> Service.get_order(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if order do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: order }}
    else
      {:error, :not_found}
    end
  end

  # TODO: Check if customer already have unlock
  def update_order(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.update_order") do
      request
      |> do_update_order()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_order(request = %{ role: role, account: account, params: %{ "id" => id }}) when role in ["guest", "customer"] do
    order = Service.get_order(%{ id: id }, %{ account: account })

    fields = cond do
      order.status == "cart" && order.grand_total_cents == 0 && request.fields["status"] == "opened" ->
        request.fields

      true ->
        Map.merge(request.fields, %{ "status" => order.status })
    end

    with {:ok, order} <- Service.update_order(id, fields, get_sopts(request)) do
      order = Translation.translate(order, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: order }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def do_update_order(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, order} <- Service.update_order(id, request.fields, get_sopts(request)) do
      order = Translation.translate(order, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: order }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_order(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.delete_order") do
      request
      |> do_delete_order()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_order(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_order(id, %{ account: account }) do

    end

    order =
      Order.Query.default()
      |> Order.Query.for_account(account.id)
      |> Repo.get(id)

    if order do
      payments = BalanceService.list_payment(%{ target_type: "Order", target_id: id }, %{ account: account })
      case length(payments) do
        0 ->
          Repo.delete!(order)
          {:ok, %AccessResponse{}}

        _ ->
          errors = %{ id: {"Order with existing payment can not be deleted", [code: :order_with_payment_cannot_be_deleted, full_error_message: true]} }
          {:error, %AccessResponse{ errors: errors }}
      end
    else
      {:error, :not_found}
    end
  end

  ####
  # Order Line Item
  ####
  ######## NOT TESTED AND NOT USED ######
  # def list_order_line_item(request = %AccessRequest{ vas: vas }) do
  #   with {:ok, role} <- Identity.authorize(vas, "storefront.list_order_line_item") do
  #     do_list_order_line_item(%{ request | role: role })
  #   else
  #     {:error, _} -> {:error, :access_denied}
  #   end
  # end
  # def do_list_order_line_item(request = %AccessRequest{ role: "customer", vas: vas, filter: filter, pagination: pagination }) do
  #   {:ok, %{ data: customer }} = Crm.do_get_customer(%AccessRequest{ role: "customer", vas: vas })

  #   filter = Map.merge(filter, %{ customer_id: customer.id })
  #   query =
  #     OrderLineItem.Query.default()
  #     |> filter_by(
  #         label: filter[:label],
  #         product_id: filter[:product_id],
  #         source_id: filter[:source_id],
  #         source_type: filter[:source_type],
  #         is_leaf: filter[:is_leaf]
  #        )
  #     |> OrderLineItem.Query.for_account(vas[:account_id])
  #     |> OrderLineItem.Query.with_order(
  #         fulfillment_status: filter[:fulfillment_status],
  #         customer_id: filter[:customer_id]
  #        )

  #   result_count = Repo.aggregate(query, :count, :id)
  #   query = paginate(query, size: pagination[:size], number: pagination[:number])

  #   order_line_items =
  #     Repo.all(query)
  #     |> Repo.preload(OrderLineItem.Query.preloads(request.preloads))
  #     |> Translation.translate(request.locale)

  #   response = %AccessResponse{
  #     meta: %{
  #       result_count: result_count,
  #     },
  #     data: order_line_items
  #   }

  #   {:ok, response}
  # end

  defp order_line_item_response(nil, _), do: {:error, :not_found}

  defp order_line_item_response(order_line_item, request = %{ account: account }) do
    preloads = OrderLineItem.Query.preloads(request.preloads, role: request.role)

    order_line_item =
      order_line_item
      |> Repo.preload(preloads)
      |> OrderLineItem.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: order_line_item }}
  end

  def create_order_line_item(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.create_order_line_item") do
      request
      |> do_create_order_line_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_order_line_item(request = %{ account: account }) do
    changeset =
      %OrderLineItem{ account_id: account.id, account: account }
      |> OrderLineItem.changeset(request.fields)

    statements =
      Multi.new()
      |> Multi.insert(:oli, changeset)
      |> Multi.run(:balanced_oli, fn(%{ oli: oli }) ->
          {:ok, OrderLineItem.balance(oli)}
         end)
      |> Multi.run(:balanced_order, fn(%{ balanced_oli: balanced_oli }) ->
          order = Repo.get!(Order, balanced_oli.order_id)
          {:ok, Order.balance(order)}
         end)
      |> Multi.run(:processed_order, fn(%{ balanced_order: balanced_order }) ->
          Order.process(balanced_order)
         end)
      |> Multi.run(:updated_order, fn(%{ processed_order: order }) ->
          {:ok, Order.refresh_payment_status(order)}
         end)

    case Repo.transaction(statements) do
      {:ok, %{ oli: oli }} ->
        order_line_item_response(oli, request)
      {:error, _, errors, _} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def update_order_line_item(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.update_order_line_item") do
      request
      |> do_update_order_line_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_order_line_item(request = %{ account: account, params: %{ "id" => id } }) do
    oli =
      OrderLineItem.Query.default()
      |> OrderLineItem.Query.for_account(account.id)
      |> Repo.get(id)

    with %OrderLineItem{} <- oli,
         changeset = %{valid?: true} <- OrderLineItem.changeset(oli, request.fields, request.locale, account.default_locale)
    do
      statements =
        Multi.new()
        |> Multi.update(:oli, changeset)
        |> Multi.run(:balanced_oli, fn(%{ oli: oli }) ->
            {:ok, OrderLineItem.balance(oli)}
           end)
        |> Multi.run(:balanced_order, fn(%{ balanced_oli: oli }) ->
            order = Repo.get!(Order, oli.order_id)
            {:ok, Order.balance(order)}
           end)
        |> Multi.run(:updated_order, fn(%{ balanced_order: order }) ->
            {:ok, Order.refresh_payment_status(order)}
           end)

      {:ok, %{ balanced_oli: oli }} = Repo.transaction(statements)
      order_line_item_response(oli, request)
    else
      nil -> {:error, :not_found}
      %{ errors: errors } ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def delete_order_line_item(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.delete_order_line_item") do
      request
      |> do_delete_order_line_item()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_order_line_item(%{ account: account, params: %{ "id" => id } }) do
    oli =
      OrderLineItem.Query.default()
      |> OrderLineItem.Query.for_account(account.id)
      |> Repo.get(id)

    statements =
      Multi.new()
      |> Multi.run(:processed_oli, fn(_) ->
          oli = oli |> Repo.preload(:order)
          OrderLineItem.process(oli, :delete)
         end)
      |> Multi.delete(:oli, oli)
      |> Multi.run(:balanced_order, fn(%{ processed_oli: oli }) ->
          {:ok, Order.balance(oli.order)}
         end)
      |> Multi.run(:updated_order, fn(%{ balanced_order: order }) ->
          {:ok, Order.refresh_payment_status(order)}
         end)

    if oli do
      {:ok, _} = Repo.transaction(statements)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end

  #
  # Unlock
  #
  defp transform_unlock_request_by_role(request = %{ account: account, vas: vas, role: "customer" }) do
    customer = CrmService.get_customer_by_user_id(vas[:user_id], %{ account: account })
    %{ request | filter: Map.put(request.filter, :customer_id, customer.id ) }
  end

  defp transform_unlock_request_by_role(request), do: request

  def list_unlock(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.list_unlock") do
      request
      |> transform_unlock_request_by_role()
      |> do_list_unlock()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_unlock(request = %{ account: account, filter: filter, pagination: pagination }) do
    data_query =
      Unlock.Query.default()
      |> filter_by(
          customer_id: filter[:customer_id],
          unlockable_id: filter[:unlockable_id]
        )
      |> Unlock.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      Unlock
      |> filter_by(customer_id: filter[:customer_id])
      |> Unlock.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    preloads = Unlock.Query.preloads(request.preloads, role: request.role)
    unlocks =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> Unlock.Proxy.put(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: unlocks
    }

    {:ok, response}
  end

  defp unlock_response(nil, _), do: {:error, :not_found}

  defp unlock_response(unlock, request = %{ account: account }) do
    preloads = Unlock.Query.preloads(request.preloads, role: request.role)

    unlock =
      unlock
      |> Repo.preload(preloads)
      |> Unlock.Proxy.put(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: unlock }}
  end

  def create_unlock(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.create_unlock") do
      request
      |> do_create_unlock()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_unlock(request = %{ account: account }) do
    changeset = Unlock.changeset(%Unlock{ account_id: account.id, account: account }, request.fields)

    with {:ok, unlock} <- Repo.insert(changeset) do
      unlock_response(unlock, request)
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  # TODO: If customer should scope by customer
  def get_unlock(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.get_unlock") do
      request
      |> transform_unlock_request_by_role()
      |> do_get_unlock()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_unlock(request = %{ account: account, filter: filter, params: %{ "id" => id } }) do
    unlock =
      Unlock.Query.default()
      |> filter_by(customer_id: filter[:customer_id])
      |> Unlock.Query.for_account(account.id)
      |> Repo.get(id)

    unlock_response(unlock, request)
  end


  def delete_unlock(request) do
    with {:ok, request} <- preprocess_request(request, "storefront.delete_unlock") do
      request
      |> do_delete_unlock()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_unlock(%{ account: account, params: %{ "id" => id } }) do
    unlock =
      Unlock.Query.default()
      |> Unlock.Query.for_account(account.id)
      |> Repo.get(id)

    if unlock do
      Repo.delete!(unlock)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end
end
