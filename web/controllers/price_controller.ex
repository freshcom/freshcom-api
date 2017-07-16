defmodule BlueJet.PriceController do
  use BlueJet.Web, :controller

  alias BlueJet.Price
  alias JaSerializer.Params
  alias BlueJet.Storefront

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{ assigns: %{ locale: locale, vas: %{ account_id: account_id, user_id: _ } } } = conn, %{ "product_item_id" => product_item_id }) do
    query =
      Price
      |> where([p], p.account_id == ^account_id)
      |> where([p], p.product_item_id == ^product_item_id)
    result_count = Repo.aggregate(query, :count, :id)
    total_count = Repo.aggregate(Price, :count, :id)

    query = paginate(query, size: conn.assigns[:page_size], number: conn.assigns[:page_number])
    product_items =
      Repo.all(query)
      |> Translation.translate_collection(locale)
    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: product_items, opts: [meta: meta, include: conn.query_params["include"], fields: conn.query_params["fields"]])
  end

  def create(conn = %{ assigns: assigns = %{ vas: %{ account_id: _, user_id: _ } } }, %{ "product_item_id" => product_item_id, "data" => data = %{ "type" => "Price" } }) do
    fields = Map.merge(Params.to_attributes(data), %{ "product_item_id" => product_item_id })
    request = %{
      vas: assigns[:vas],
      fields: fields,
      preloads: assigns[:preloads]
    }

    case Storefront.create_price(request) do
      {:ok, price} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: price, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    price =
      Price
      |> Repo.get_by!(account_id: account_id, id: id)

    render(conn, "show.json-api", data: price, opts: [include: conn.query_params["include"]])
  end

  def update(%{ assigns: %{ locale: locale, vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id, "data" => data = %{"type" => "Price", "attributes" => _price_params}}) do
    price = Repo.get_by!(Price, account_id: account_id, id: id)
    changeset = Price.changeset(price, Params.to_attributes(data), locale)

    case Repo.update(changeset) do
      {:ok, price} ->
        price = Translation.translate(price, locale)
        render(conn, "show.json-api", data: price)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    price = Repo.get_by!(Price, account_id: account_id, id: id)
    Repo.delete!(price)

    send_resp(conn, :no_content, "")
  end

end
