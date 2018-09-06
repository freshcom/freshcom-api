defmodule BlueJetWeb.PointTransactionController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Crm

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns }, %{ "point_account_id" => point_account_id }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "point_account_id" => point_account_id },
      pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %ContextResponse{ data: point_transactions, meta: meta }} = Crm.list_point_transaction(request)

    render(conn, "index.json-api", data: point_transactions, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns }, %{ "point_account_id" => point_account_id, "data" => data = %{ "type" => "PointTransaction" } }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "point_account_id" => point_account_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Crm.create_point_transaction(request) do
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
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Crm.get_point_transaction(request) do
      {:ok, %{ data: point_transaction, meta: meta }} ->
        render(conn, "show.json-api", data: point_transaction, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => id }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      params: %{ "id" => id }
    }

    case Crm.delete_point_transaction(request) do
      {:ok, _} -> send_resp(conn, :no_content, "")

      other -> other
    end
  end
end
