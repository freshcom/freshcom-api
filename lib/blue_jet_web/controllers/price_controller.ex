defmodule BlueJetWeb.PriceController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Catalogue

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
    %{ prices: prices, total_count: total_count, result_count: result_count } = Catalogue.list_prices(request)

    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: prices, opts: [meta: meta, include: conn.query_params["include"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "data" => data = %{ "type" => "Price" } }) do
    request = %{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case Catalogue.create_price(request) do
      {:ok, price} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: price, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: %{ account_id: _ } } }, %{ "id" => price_id }) do
    request = %{
      vas: assigns[:vas],
      price_id: price_id,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    price = Catalogue.get_price!(request)

    render(conn, "show.json-api", data: price, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => price_id, "data" => data = %{ "type" => "Price" } }) do
    request = %{
      vas: assigns[:vas],
      price_id: price_id,
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Catalogue.update_price(request) do
      {:ok, price} ->
        render(conn, "show.json-api", data: price, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def delete(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "id" => price_id }) do
    request = %{
      vas: assigns[:vas],
      price_id: price_id
    }

    case Catalogue.delete_price!(request) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")
      {:error, errors} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end
end
