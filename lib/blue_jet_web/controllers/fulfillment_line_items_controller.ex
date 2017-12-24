defmodule BlueJetWeb.FulfillmentLineItemController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Distribution

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # def index(conn = %{ assigns: assigns }, params) do
  #   request = %AccessRequest{
  #     vas: assigns[:vas],
  #     filter: assigns[:filter],
  #     pagination: %{ size: assigns[:page_size], number: assigns[:page_number] },
  #     preloads: assigns[:preloads],
  #     locale: assigns[:locale]
  #   }

  #   case Distribution.list_fulfillment_line_item(request) do
  #     {:ok, %{ data: fulfillment_line_items, meta: meta }} ->
  #       render(conn, "index.json-api", data: fulfillment_line_items, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

  #     other -> other
  #   end
  # end

  # def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "Payment" } }) do
  #   request = %AccessRequest{
  #     vas: assigns[:vas],
  #     fields: Params.to_attributes(data),
  #     preloads: assigns[:preloads]
  #   }

  #   case Distribution.create_fulfillment_line_item(request) do
  #     {:ok, %{ data: fulfillment_line_item, meta: meta }} ->
  #       conn
  #       |> put_status(:created)
  #       |> render("show.json-api", data: fulfillment_line_item, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

  #     {:error, %{ errors: errors }} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(:errors, data: extract_errors(errors))

  #     other -> other
  #   end
  # end

  # def show(conn = %{ assigns: assigns }, %{ "id" => id }) do
  #   request = %AccessRequest{
  #     vas: assigns[:vas],
  #     params: %{ "id" => id },
  #     preloads: assigns[:preloads],
  #     locale: assigns[:locale]
  #   }

  #   case Distribution.get_fulfillment_line_item(request) do
  #     {:ok, %{ data: fulfillment_line_item, meta: meta }} ->
  #       render(conn, "show.json-api", data: fulfillment_line_item, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

  #     other -> other
  #   end
  # end

  def update(conn = %{ assigns: assigns }, %{ "id" => id, "data" => data = %{ "type" => "FulfillmentLineItem" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Distribution.update_fulfillment_line_item(request) do
      {:ok, %{ data: fli, meta: meta }} ->
        render(conn, "show.json-api", data: fli, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id }
    }

    case Distribution.delete_fulfillment_line_item(request) do
      {:ok, _} -> send_resp(conn, :no_content, "")

      other -> other
    end
  end
end
