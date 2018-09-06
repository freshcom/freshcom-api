defmodule BlueJetWeb.ReturnItemController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Fulfillment

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "ReturnItem" } }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Fulfillment.create_return_item(request) do
      {:ok, %{ data: return_item, meta: meta }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: return_item, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end
end
