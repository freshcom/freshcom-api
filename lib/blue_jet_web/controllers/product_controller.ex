defmodule BlueJetWeb.ProductController do
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

   {:ok, %AccessResponse{ data: products, meta: meta }} = Catalogue.list_product(request)

    render(conn, "index.json-api", data: products, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "Product" } }) do
    fields =
      Params.to_attributes(data)
      |> underscore_value(["kind", "name_sync"])

    request = %AccessRequest{
      vas: assigns[:vas],
      fields: fields,
      preloads: assigns[:preloads]
    }

    case Catalogue.create_product(request) do
      {:ok, %AccessResponse{ data: product }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: product, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns }, %{ "id" => id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: product }} = Catalogue.get_product(request)

    render(conn, "show.json-api", data: product, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => id, "data" => data = %{ "type" => "Product" } }) do
    fields =
      Params.to_attributes(data)
      |> underscore_value(["kind", "name_sync"])

    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      fields: fields,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Catalogue.update_product(request) do
      {:ok, %AccessResponse{ data: product }} ->
        render(conn, "show.json-api", data: product, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => product_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ product_id: product_id }
    }

    Catalogue.delete_product(request)

    send_resp(conn, :no_content, "")
  end

end
