defmodule BlueJetWeb.UnlockController do
  use BlueJetWeb, :controller

  alias BlueJet.Storefront

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

    case Storefront.list_unlock(request) do
      {:ok, %{ data: unlocks, meta: meta }} ->
        render(conn, "index.json-api", data: unlocks, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

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

    case Storefront.get_unlock(request) do
      {:ok, %{ data: unlock, meta: meta }} ->
        render(conn, "show.json-api", data: unlock, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end
end
