defmodule BlueJetWeb.RefundController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Billing

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "payment_id" => payment_id, "data" => data = %{ "type" => "Refund" } }) do
    fields = Map.merge(Params.to_attributes(data), %{ "payment_id" => payment_id })
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ payment_id: payment_id },
      fields: fields,
      preloads: assigns[:preloads]
    }

    case Billing.create_refund(request) do
      {:ok, %AccessResponse{ data: refund }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: refund, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => payment_id }) when map_size(vas) == 2 do
    request = %{
      vas: assigns[:vas],
      payment_id: payment_id,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    payment = Storefront.get_payment!(request)

    render(conn, "show.json-api", data: payment, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => payment_id, "data" => data = %{"type" => "Payment" } }) when map_size(vas) == 2 do
    request = %{
      vas: assigns[:vas],
      payment_id: payment_id,
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Storefront.update_payment(request) do
      {:ok, payment} ->
        render(conn, "show.json-api", data: payment, opts: [include: conn.query_params["include"]])
      {:error, errors} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end
end
