defmodule BlueJetWeb.CustomerController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Identity
  alias BlueJet.CRM

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

    {:ok, %AccessResponse{ data: customers, meta: meta }} = CRM.list_customer(request)

    render(conn, "index.json-api", data: customers, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "Customer" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case CRM.create_customer(request) do
      {:ok, %AccessResponse{ data: customer }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: customer, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, params) do
    params = Map.drop(params, ["locale"])
    request = %AccessRequest{
      vas: assigns[:vas],
      params: params,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    with {:ok, %AccessResponse{ data: customer }} <- CRM.get_customer(request) do
      render(conn, "show.json-api", data: customer, opts: [include: conn.query_params["include"]])
    end
  end

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => id, "data" => data = %{ "type" => "Customer" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case CRM.update_customer(request) do
      {:ok, %AccessResponse{ data: customer }} ->
        render(conn, "show.json-api", data: customer, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => customer_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ customer_id: customer_id }
    }

    CRM.delete_customer(request)

    send_resp(conn, :no_content, "")
  end
end
