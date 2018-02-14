defmodule BlueJetWeb.ReturnPackageController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Fulfillment

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, _) do
    request = %AccessRequest{
      vas: assigns[:vas],
      filter: assigns[:filter],
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Fulfillment.list_return_package(request) do
      {:ok, %{ data: return_packages, meta: meta }} ->
        render(conn, "index.json-api", data: return_packages, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end
end
