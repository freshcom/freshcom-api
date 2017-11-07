defmodule BlueJetWeb.SkuController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Inventory

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, params) do
    request = %AccessRequest{
      vas: assigns[:vas],
      search: params["search"],
      params: %{ account_id: params["account_id"] },
      filter: assigns[:filter],
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: skus, meta: meta }} = Inventory.list_sku(request)

    render(conn, "index.json-api", data: skus, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "Sku" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Inventory.create_sku(request) do
      {:ok, %AccessResponse{ data: sku }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: sku, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => sku_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ sku_id: sku_id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: sku }} = Inventory.get_sku(request)

    render(conn, "show.json-api", data: sku, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => sku_id, "data" => data = %{ "type" => "Sku" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ sku_id: sku_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Inventory.update_sku(request) do
      {:ok, %AccessResponse{ data: sku }} ->
        render(conn, "show.json-api", data: sku, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => sku_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ sku_id: sku_id }
    }

    Inventory.delete_sku(request)

    send_resp(conn, :no_content, "")
  end
end
