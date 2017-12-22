defmodule BlueJetWeb.PointTransactionController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.CRM

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # def index(conn = %{ assigns: assigns }, params) do
  #   request = %AccessRequest{
  #     vas: assigns[:vas],
  #     search: params["search"],
  #     filter: assigns[:filter],
  #     pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
  #     preloads: assigns[:preloads],
  #     locale: assigns[:locale]
  #   }

  #   {:ok, %AccessResponse{ data: point_transactions, meta: meta }} = CRM.list_point_transaction(request)

  #   render(conn, "index.json-api", data: point_transactions, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  # end

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "PointTransaction" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case CRM.create_point_transaction(request) do
      {:ok, %{ data: point_transaction, meta: meta }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: point_transaction, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

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

    case CRM.get_point_transaction(request) do
      {:ok, %{ data: point_transaction, meta: meta }} ->
        render(conn, "show.json-api", data: point_transaction, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end
end
