defmodule BlueJet.ProductItemController do
  use BlueJet.Web, :controller

  alias BlueJet.ProductItem
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    product_items = Repo.all(ProductItem)
    render(conn, "index.json-api", data: product_items)
  end

  def create(conn, %{"data" => data = %{"type" => "product_item", "attributes" => _product_item_params}}) do
    changeset = ProductItem.changeset(%ProductItem{}, Params.to_attributes(data))

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

  def show(conn, %{"id" => id}) do
    product_item = Repo.get!(ProductItem, id)
    render(conn, "show.json-api", data: product_item)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "product_item", "attributes" => _product_item_params}}) do
    product_item = Repo.get!(ProductItem, id)
    changeset = ProductItem.changeset(product_item, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, product_item} ->
        render(conn, "show.json-api", data: product_item)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    product_item = Repo.get!(ProductItem, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(product_item)

    send_resp(conn, :no_content, "")
  end

end
