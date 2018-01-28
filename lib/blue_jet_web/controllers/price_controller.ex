defmodule BlueJetWeb.PriceController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Catalogue

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, params) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "product_id" => params["product_id"] },
      search: params["search"],
      filter: assigns[:filter],
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Catalogue.list_price(request) do
      {:ok, %{ data: prices, meta: meta }} ->
        render(conn, "index.json-api", data: prices, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def create(conn = %{ assigns: assigns }, %{ "product_id" => product_id, "data" => data = %{ "type" => "Price" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "product_id" => product_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Catalogue.create_price(request) do
      {:ok, %{ data: price, meta: meta }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: price, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def show(conn = %{ assigns: assigns }, %{ "id" => id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Catalogue.get_price(request) do
      {:ok, %{ data: price, meta: meta }} ->
        render(conn, "show.json-api", data: price, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => id, "data" => data = %{ "type" => "Price" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Catalogue.update_price(request) do
      {:ok, %{ data: price, meta: meta }} ->
        render(conn, "show.json-api", data: price, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id }
    }

    case Catalogue.delete_price(request) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end
end
