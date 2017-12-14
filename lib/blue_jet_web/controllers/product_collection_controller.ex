defmodule BlueJetWeb.ProductCollectionController do
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

   {:ok, %AccessResponse{ data: product_collections, meta: meta }} = Catalogue.list_product_collection(request)

    render(conn, "index.json-api", data: product_collections, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
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
      {:ok, %AccessResponse{ data: product_collection }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: product_collection, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns }, params) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: params,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: product_collection }} = Catalogue.get_product_collection(request)

    render(conn, "show.json-api", data: product_collection, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => id, "data" => data = %{ "type" => "ProductCollection" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ id: id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Catalogue.update_product_collection(request) do
      {:ok, %AccessResponse{ data: product_collection }} ->
        render(conn, "show.json-api", data: product_collection, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  # def delete(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => id }) do
  #   request = %AccessRequest{
  #     vas: assigns[:vas],
  #     params: %{ id: id }
  #   }

  #   {:ok, _} = Catalogue.delete_product_collection(request)

  #   send_resp(conn, :no_content, "")
  # end

end
