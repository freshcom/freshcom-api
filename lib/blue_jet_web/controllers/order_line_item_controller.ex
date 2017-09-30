defmodule BlueJetWeb.OrderLineItemController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Storefront

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns = %{ vas: %{ account_id: _ } } }, params) do
    request = %{
      vas: assigns[:vas],
      search_keyword: params["search"],
      filter: assigns[:filter],
      page_size: assigns[:page_size],
      page_number: assigns[:page_number],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }
    %{ orders: orders, total_count: total_count, result_count: result_count } = Storefront.list_order_line_items(request)

    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: orders, opts: [meta: meta, include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "order_id" => order_id, "data" => data = %{ "type" => "OrderLineItem" } }) when map_size(vas) == 2 do
    fields = Map.merge(Params.to_attributes(data), %{ "order_id" => order_id })
    request = %{
      vas: assigns[:vas],
      fields: fields,
      preloads: assigns[:preloads]
    }

    case Storefront.create_order_line_item(request) do
      {:ok, order} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: order, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => order_id }) when map_size(vas) == 2 do
    request = %{
      vas: assigns[:vas],
      order_id: order_id,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    order = Storefront.get_order!(request)

    render(conn, "show.json-api", data: order, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => order_id, "data" => data = %{"type" => "Order" } }) when map_size(vas) == 2 do
    request = %{
      vas: assigns[:vas],
      order_id: order_id,
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Storefront.update_order(request) do
      {:ok, order} ->
        render(conn, "show.json-api", data: order, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => order_line_item_id }) do
    request = %{
      vas: assigns[:vas],
      order_line_item_id: order_line_item_id
    }

    Storefront.delete_order_line_item!(request)

    send_resp(conn, :no_content, "")
  end
end
