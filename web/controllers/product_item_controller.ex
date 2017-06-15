defmodule BlueJet.ProductItemController do
  use BlueJet.Web, :controller

  alias BlueJet.ProductItem
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, params) do
    query =
      ProductItem
      |> where([s], s.account_id == ^account_id)
      |> search([:short_name, :id], params["search"], conn.assigns[:locale])
    result_count = Repo.aggregate(query, :count, :id)
    total_count = Repo.aggregate(ProductItem, :count, :id)

    query = paginate(query, size: conn.assigns[:page_size], number: conn.assigns[:page_number])
    skus =
      Repo.all(query)
      |> Translation.translate_collection(conn.assigns[:locale])
    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: skus, opts: [meta: meta, fields: conn.query_params["fields"]])
  end

  def create(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"product_id" => product_id, "data" => data = %{"type" => "ProductItem", "attributes" => _product_item_params}}) do
    fields = Map.merge(Params.to_attributes(data), %{ "account_id" => account_id, "product_id" => product_id })
    changeset = ProductItem.changeset(%ProductItem{}, fields)

    case Repo.insert(changeset) do
      {:ok, product_item} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", product_item_path(conn, :show, product_item))
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

  def update(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id, "data" => data = %{"type" => "ProductItem", "attributes" => _product_item_params}}) do
    product_item = Repo.get_by!(ProductItem, account_id: account_id, id: id)
    changeset = ProductItem.changeset(product_item, Params.to_attributes(data), conn.assigns[:locale])

    case Repo.update(changeset) do
      {:ok, product_item} ->
        product_item = Translation.translate(product_item, conn.assigns[:locale])
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
