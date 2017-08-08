defmodule BlueJetWeb.SkuController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Inventory

  action_fallback BlueJetWeb.FallbackController

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
    %{ skus: skus, total_count: total_count, result_count: result_count } = Inventory.list_skus(request)

    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: skus, opts: [meta: meta, include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "data" => data = %{ "type" => "Sku" } }) do
    request = %{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Inventory.create_sku(request) do
      {:ok, sku} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: sku, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => sku_id }) do
    request = %{
      vas: assigns[:vas],
      sku_id: sku_id,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    sku = Inventory.get_sku!(request)

    render(conn, "show.json-api", data: sku, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => sku_id, "data" => data = %{ "type" => "Sku" } }) do
    request = %{
      vas: assigns[:vas],
      sku_id: sku_id,
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Inventory.update_sku(request) do
      {:ok, sku} ->
        render(conn, "show.json-api", data: sku, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => sku_id }) do
    request = %{
      vas: assigns[:vas],
      sku_id: sku_id
    }

    Inventory.delete_sku!(request)

    send_resp(conn, :no_content, "")
  end
end
