defmodule BlueJetWeb.PaymentController do
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

    {:ok, %AccessResponse{ data: payments, meta: meta }} = Billing.list_payment(request)

    render(conn, "index.json-api", data: payments, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "Payment" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Billing.create_payment(request) do
      {:ok, %AccessResponse{ data: payment }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: payment, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns }, %{ "id" => payment_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ payment_id: payment_id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: payment }} = Billing.get_payment(request)

    render(conn, "show.json-api", data: payment, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => payment_id, "data" => data = %{ "type" => "Payment" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ payment_id: payment_id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Billing.update_payment(request) do
      {:ok, %AccessResponse{ data: payment }} ->
        render(conn, "show.json-api", data: payment, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => payment_id }) do
    request = %{
      vas: assigns[:vas],
      payment_id: payment_id
    }

    Billing.delete_payment!(request)

    send_resp(conn, :no_content, "")
  end
end
