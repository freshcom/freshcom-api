defmodule BlueJetWeb.DepositableController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Goods

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

    {:ok, %AccessResponse{ data: depositables, meta: meta }} = Goods.list_depositable(request)

    render(conn, "index.json-api", data: depositables, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "Depositable" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Goods.create_depositable(request) do
      {:ok, %AccessResponse{ data: depositable }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: depositable, opts: [include: conn.query_params["include"]])
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

    {:ok, %AccessResponse{ data: depositable }} = Goods.get_depositable(request)

    render(conn, "show.json-api", data: depositable, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => id, "data" => data = %{ "type" => "Depositable" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Goods.update_depositable(request) do
      {:ok, %AccessResponse{ data: depositable }} ->
        render(conn, "show.json-api", data: depositable, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id }
    }

    Goods.delete_depositable(request)

    send_resp(conn, :no_content, "")
  end
end
