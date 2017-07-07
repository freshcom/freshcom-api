defmodule BlueJet.ProductItemController do
  use BlueJet.Web, :controller

  alias BlueJet.ProductItem
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{ assigns: %{ locale: locale, vas: %{ account_id: account_id, user_id: _ } } } = conn, params) do
    query =
      ProductItem
      |> where([s], s.account_id == ^account_id)
      |> filter(product_id: conn.query_params["filter"]["productId"], sku_id: conn.query_params["filter"]["skuId"], unlockable_id: conn.query_params["filter"]["unlockableId"])
      |> search([:short_name, :id], params["search"], locale)
    result_count = Repo.aggregate(query, :count, :id)
    total_count = Repo.aggregate(ProductItem, :count, :id)

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

  def create(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"product_id" => product_id, "data" => data = %{"type" => "ProductItem", "attributes" => _product_item_params}}) do
    fields = Map.merge(Params.to_attributes(data), %{ "account_id" => account_id, "product_id" => product_id })
    changeset = ProductItem.changeset(%ProductItem{}, fields)

    case Repo.insert(changeset) do
      {:ok, product_item} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: product_item)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    product_item =
      ProductItem
      |> Repo.get_by!(account_id: account_id, id: id)

    render(conn, "show.json-api", data: product_item, opts: [include: conn.query_params["include"]])
  end

  def update(%{ assigns: %{ locale: locale, vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id, "data" => data = %{"type" => "ProductItem", "attributes" => _product_item_params}}) do
    product_item = Repo.get_by!(ProductItem, account_id: account_id, id: id)
    changeset = ProductItem.changeset(product_item, Params.to_attributes(data), locale)

    case Repo.update(changeset) do
      {:ok, product_item} ->
        product_item = Translation.translate(product_item, locale)
        render(conn, "show.json-api", data: product_item)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    product_item = Repo.get_by!(ProductItem, account_id: account_id, id: id)
    Repo.delete!(product_item)

    send_resp(conn, :no_content, "")
  end

end
