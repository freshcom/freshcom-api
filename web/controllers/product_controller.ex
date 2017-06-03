defmodule BlueJet.ProductController do
  use BlueJet.Web, :controller

  alias BlueJet.Product
  alias JaSerializer.Params
  alias BlueJet.Translation

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, params) do
    query =
      Product
      |> where([s], s.account_id == ^account_id)
      |> search([:name, :id], params["search"], conn.assigns[:locale])
    result_count = Repo.aggregate(query, :count, :id)
    total_count = Repo.aggregate(Product, :count, :id)

    query = paginate(query, size: conn.assigns[:page_size], number: conn.assigns[:page_number])
    products =
      Repo.all(query)
      |> Translation.translate_collection(conn.assigns[:locale])
    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: products, opts: [meta: meta, fields: conn.query_params["fields"]])
  end

  def create(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"data" => data = %{"type" => "Product", "attributes" => _product_params}}) do
    params = Map.merge(Params.to_attributes(data), %{ "account_id" => account_id })
    changeset = Product.changeset(%Product{}, params, conn.assigns[:locale])

    case Repo.insert(changeset) do
      {:ok, product} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: product)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    product =
      Product
      |> Repo.get_by!(account_id: account_id, id: id)
      |> Translation.translate(conn.assigns[:locale])

    render(conn, "show.json-api", data: product, opts: [include: conn.query_params["include"]])
  end

  def update(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id, "data" => data = %{"type" => "Product", "attributes" => _product_params}}) do
    product = Repo.get_by!(Product, account_id: account_id, id: id)
    changeset = Product.changeset(product, Params.to_attributes(data), conn.assigns[:locale])

    case Repo.update(changeset) do
      {:ok, product} ->
        product = Translation.translate(product, conn.assigns[:locale])
        render(conn, "show.json-api", data: product)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    product = Repo.get_by!(Product, account_id: account_id, id: id)
    Repo.delete!(product)

    send_resp(conn, :no_content, "")
  end

end
