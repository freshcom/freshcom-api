defmodule BlueJetWeb.ProductItemController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Catalogue

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

   {:ok, %AccessResponse{ data: product_items, meta: meta }} = Catalogue.list_product_item(request)

    render(conn, "index.json-api", data: product_items, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "ProductItem" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Catalogue.create_product_item(request) do
      {:ok, %AccessResponse{ data: product_item }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: product_item, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => product_item_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ product_item_id: product_item_id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: product_item }} = Catalogue.get_product_item(request)

    render(conn, "show.json-api", data: product_item, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => product_item_id, "data" => data = %{ "type" => "ProductItem" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ product_item_id: product_item_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Catalogue.update_product_item(request) do
      {:ok, %AccessResponse{ data: product_item }} ->
        render(conn, "show.json-api", data: product_item, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => product_item_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ product_item_id: product_item_id }
    }

    case Catalogue.delete_product_item(request) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

end
