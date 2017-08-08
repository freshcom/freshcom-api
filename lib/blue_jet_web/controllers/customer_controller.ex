defmodule BlueJetWeb.CustomerController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Identity

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, params) do
    request = %{
      vas: assigns[:vas],
      search_keyword: params["search"],
      filter: assigns[:filter],
      page_size: assigns[:page_size],
      page_number: assigns[:page_number],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    %{ customers: customers, total_count: total_count, result_count: result_count } = Identity.list_customers(request)

    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: customers, opts: [meta: meta, include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: %{ account_id: _ } } }, %{ "data" => data = %{ "type" => "Customer" } }) do
    preloads = assigns[:preloads] ++ [:refresh_token]
    request = %{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: preloads
    }


    case Identity.create_customer(request) do
      {:ok, customer} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: customer, opts: [include: Enum.join(preloads, ",")])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, params) when map_size(vas) == 2 do
    request = %{
      vas: assigns[:vas],
      customer_id: vas[:customer_id] || params["id"],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    customer = Identity.get_customer!(request)

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
