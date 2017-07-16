defmodule BlueJet.ProductItemController do
  use BlueJet.Web, :controller

  alias JaSerializer.Params
  alias BlueJet.Storefront

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, params) do
    request = %{
      vas: assigns[:vas],
      search_keyword: params["search"],
      filter: assigns[:filter],
      page_size: assigns[:page_size],
      page_number: assigns[:page_number],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    %{ product_items: product_items, total_count: total_count, result_count: result_count } = Storefront.list_product_items(request)

    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: product_items, opts: [meta: meta, include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "product_id" => product_id, "data" => data = %{ "type" => "ProductItem" } }) do
    fields = Map.merge(Params.to_attributes(data), %{ "product_id" => product_id })
    request = %{
      vas: assigns[:vas],
      fields: fields,
      preloads: assigns[:preloads]
    }

    case Storefront.create_product_item(request) do
      {:ok, product_item} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: product_item, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: %{ account_id: _ } } }, %{ "id" => product_item_id }) do
    request = %{
      vas: assigns[:vas],
      product_item_id: product_item_id,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    product_item = Storefront.get_product_item!(request)

    render(conn, "show.json-api", data: product_item, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => product_item_id, "data" => data = %{ "type" => "ProductItem" } }) do
    request = %{
      vas: assigns[:vas],
      product_item_id: product_item_id,
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Storefront.update_product_item(request) do
      {:ok, product_item} ->
        render(conn, "show.json-api", data: product_item, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => product_item_id }) do
    request = %{
      vas: assigns[:vas],
      product_item_id: product_item_id
    }

    Storefront.delete_product_item!(request)

    send_resp(conn, :no_content, "")
  end

end
