defmodule BlueJetWeb.DepositableController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Goods

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, params) do
    request = %ContextRequest{
      vas: assigns[:vas],
      search: params["search"],
      filter: assigns[:filter],
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Goods.list_depositable(request) do
      {:ok, %ContextResponse{ data: depositables, meta: meta }} ->
        render(conn, "index.json-api", data: depositables, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "Depositable" } }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Goods.create_depositable(request) do
      {:ok, %ContextResponse{ data: depositable, meta: meta }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: depositable, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %ContextResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def show(conn = %{ assigns: assigns }, %{ "id" => id }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Goods.get_depositable(request) do
      {:ok, %ContextResponse{ data: depositable, meta: meta }} ->
        render(conn, "show.json-api", data: depositable, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => id, "data" => data = %{ "type" => "Depositable" } }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Goods.update_depositable(request) do
      {:ok, %ContextResponse{ data: depositable, meta: meta }} ->
        render(conn, "show.json-api", data: depositable, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %ContextResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => id }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "id" => id }
    }

    case Goods.delete_depositable(request) do
      {:ok, _} -> send_resp(conn, :no_content, "")

      other -> other
    end
  end
end
