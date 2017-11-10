defmodule BlueJetWeb.PriceController do
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

    {:ok, %AccessResponse{ data: prices, meta: meta }} = Catalogue.list_price(request)

    render(conn, "index.json-api", data: prices, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "Price" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Catalogue.create_price(request) do
      {:ok, %AccessResponse{ data: price }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: price, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => price_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ price_id: price_id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: price }} = Catalogue.get_price(request)

    render(conn, "show.json-api", data: price, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => price_id, "data" => data = %{ "type" => "Price" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ price_id: price_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Catalogue.update_price(request) do
      {:ok, %AccessResponse{ data: price }} ->
        render(conn, "show.json-api", data: price, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => price_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ price_id: price_id }
    }

    case Catalogue.delete_price(request) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end
end
