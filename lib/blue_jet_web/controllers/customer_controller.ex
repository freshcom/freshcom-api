defmodule BlueJetWeb.CustomerController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Identity
  alias BlueJet.Storefront

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

    {:ok, %AccessResponse{ data: customers, meta: meta }} = Storefront.list_customer(request)

    render(conn, "index.json-api", data: customers, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "Sku" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Storefront.create_customer(request) do
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

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => customer_id }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      params: %{ customer_id: customer_id },
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: customer }} = Storefront.get_customer(request)

    render(conn, "show.json-api", data: customer, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "id" => customer_id, "data" => data = %{ "type" => "Customer" } }) when map_size(vas) == 2 do
    request = %{
      vas: assigns[:vas],
      customer_id: customer_id,
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Identity.update_customer(request) do
      {:ok, customer} ->
        render(conn, "show.json-api", data: customer, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => customer_id }) do
    request = %{
      vas: assigns[:vas],
      customer_id: customer_id
    }

    Identity.delete_customer!(request)

    send_resp(conn, :no_content, "")
  end

end
