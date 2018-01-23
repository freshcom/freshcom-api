defmodule BlueJetWeb.CustomerController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Crm

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

    case Crm.list_customer(request) do
      {:ok, %AccessResponse{ data: customers, meta: meta }} ->
        render(conn, "index.json-api", data: customers, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def create(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "Customer" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Crm.create_customer(request) do
      {:ok, %{ data: customer, meta: meta }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: customer, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end

  def show(conn = %{ assigns: assigns }, params) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: params,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Crm.get_customer(request) do
      {:ok, %{ data: customer, meta: meta }} ->
        render(conn, "show.json-api", data: customer, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

      other -> other
    end
  end

  def update(conn = %{ assigns: assigns }, %{ "id" => id, "data" => data = %{ "type" => "Customer" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ "id" => id },
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Crm.update_customer(request) do
      {:ok, %{ data: customer, meta: meta }} ->
        render(conn, "show.json-api", data: customer, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])

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

    case Crm.delete_customer(request) do
      {:ok, _} -> send_resp(conn, :no_content, "")

      other -> other
    end
  end
end
