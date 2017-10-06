defmodule BlueJetWeb.PaymentController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Storefront

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns = %{ vas: %{ account_id: _ } } }, params) do
    request = %{
      vas: assigns[:vas],
      search_keyword: params["search"],
      filter: assigns[:filter],
      page_size: assigns[:page_size],
      page_number: assigns[:page_number],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }
    %{ payments: payments, total_count: total_count, result_count: result_count } = Storefront.list_payments(request)

    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: payments, opts: [meta: meta, include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "order_id" => order_id, "data" => data = %{ "type" => "Payment" } }) when map_size(vas) == 2 do
    fields = Map.merge(Params.to_attributes(data), %{ "order_id" => order_id })
    request = %{
      vas: assigns[:vas],
      fields: fields,
      preloads: assigns[:preloads]
    }

    case Storefront.create_payment(request) do
      {:ok, payment} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: payment, opts: [include: conn.query_params["include"]])
      {:error, errors} ->
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

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => payment_id, "data" => data = %{"type" => "Order" } }) when map_size(vas) == 2 do
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
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => payment_id }) do
    request = %{
      vas: assigns[:vas],
      payment_id: payment_id
    }

    Storefront.delete_payment!(request)

    send_resp(conn, :no_content, "")
  end
end
