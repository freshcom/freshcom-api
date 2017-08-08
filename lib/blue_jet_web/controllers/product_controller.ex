defmodule BlueJetWeb.ProductController do
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
    %{ products: products, total_count: total_count, result_count: result_count } = Storefront.list_products(request)

    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: products, opts: [meta: meta, include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "data" => data = %{ "type" => "Product" } }) do
    request = %{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Storefront.create_product(request) do
      {:ok, product} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: product, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: %{ account_id: _ } } }, %{ "id" => product_id }) do
    request = %{
      vas: assigns[:vas],
      product_id: product_id,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    product = Storefront.get_product!(request)

    render(conn, "show.json-api", data: product, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => product_id, "data" => data = %{"type" => "Product" } }) do
    request = %{
      vas: assigns[:vas],
      product_id: product_id,
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Storefront.update_product(request) do
      {:ok, product} ->
        render(conn, "show.json-api", data: product, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => product_id }) do
    request = %{
      vas: assigns[:vas],
      product_id: product_id
    }

    Storefront.delete_product!(request)

    send_resp(conn, :no_content, "")
  end

end
