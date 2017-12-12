defmodule BlueJetWeb.OrderLineItemController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Storefront

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, params) do
    request = %AccessRequest{
      vas: assigns[:vas],
      search: params["search"],
      filter: assigns[:filter],
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: order_line_items, meta: meta }} = Storefront.list_order_line_item(request)

    render(conn, "index.json-api", data: order_line_items, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "order_id" => order_id, "data" => data = %{ "type" => "OrderLineItem" } }) do
    fields = Map.merge(Params.to_attributes(data), %{ "order_id" => order_id })
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: fields,
      preloads: assigns[:preloads]
    }

    case Storefront.create_order_line_item(request) do
      {:ok, %AccessResponse{ data: oli }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: oli, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
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

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => oli_id, "data" => data = %{ "type" => "OrderLineItem" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ order_line_item_id: oli_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Storefront.update_order_line_item(request) do
      {:ok, %AccessResponse{ data: oli }} ->
        render(conn, "show.json-api", data: oli, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => oli_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ order_line_item_id: oli_id }
    }

    Storefront.delete_order_line_item(request)

    send_resp(conn, :no_content, "")
  end
end
