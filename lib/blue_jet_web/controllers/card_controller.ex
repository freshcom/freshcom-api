defmodule BlueJetWeb.CardController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Billing

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

    {:ok, %AccessResponse{ data: cards, meta: meta }} = Billing.list_card(request)

    render(conn, "index.json-api", data: cards, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  # def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "order_id" => order_id, "data" => data = %{ "type" => "Payment" } }) when map_size(vas) == 2 do
  #   fields = Map.merge(Params.to_attributes(data), %{ "order_id" => order_id })
  #   request = %{
  #     vas: assigns[:vas],
  #     fields: fields,
  #     preloads: assigns[:preloads]
  #   }

  #   case Storefront.create_payment(request) do
  #     {:ok, payment} ->
  #       conn
  #       |> put_status(:created)
  #       |> render("show.json-api", data: payment, opts: [include: conn.query_params["include"]])
  #     {:error, errors} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(:errors, data: extract_errors(errors))
  #   end
  # end

  # def show(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => payment_id }) when map_size(vas) == 2 do
  #   request = %{
  #     vas: assigns[:vas],
  #     payment_id: payment_id,
  #     preloads: assigns[:preloads],
  #     locale: assigns[:locale]
  #   }

  #   payment = Storefront.get_payment!(request)

  #   render(conn, "show.json-api", data: payment, opts: [include: conn.query_params["include"]])
  # end

  def update(conn = %{ assigns: assigns }, %{ "id" => card_id, "data" => data = %{ "type" => "Card" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ card_id: card_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Billing.update_card(request) do
      {:ok, %AccessResponse{ data: card }} ->
        render(conn, "show.json-api", data: card, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns }, %{ "id" => card_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ card_id: card_id }
    }

    Billing.delete_card(request)

    send_resp(conn, :no_content, "")
  end
end
