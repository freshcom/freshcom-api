defmodule BlueJetWeb.ProductCollectionController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Catalogue

  action_fallback BlueJetWeb.FallbackController

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

    case Catalogue.list_product_collection(request) do
      {:ok, %{ data: product_collections, meta: meta }} ->
        render(conn, "index.json-api", data: product_collections, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "ProductCollection" } }) do
    fields =
      Params.to_attributes(data)
      |> underscore_value(["kind", "name_sync"])

    request = %AccessRequest{
      vas: vas,
      fields: fields,
      preloads: assigns[:preloads]
    }

    case Catalogue.create_product_collection(request) do
      {:ok, %{ data: product_collection, meta: meta }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: product_collection, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def show(conn = %{ assigns: assigns }, params) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: params,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Catalogue.get_product_collection(request) do
      {:ok, %{ data: product_collection, meta: meta }} ->
        render(conn, "show.json-api", data: product_collection, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => id, "data" => data = %{ "type" => "ProductCollection" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Catalogue.update_product_collection(request) do
      {:ok, %{ data: product_collection, meta: meta }} ->
        render(conn, "show.json-api", data: product_collection, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => pc_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => pc_id }
    }

    {:ok, _} = Catalogue.delete_product_collection(request)

    send_resp(conn, :no_content, "")
  end
end
