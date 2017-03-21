require IEx;

defmodule BlueJet.ProductController do
  use BlueJet.Web, :controller

  alias BlueJet.Product
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    products = Repo.all(Product)
    render(conn, "index.json-api", data: products)
  end

  def create(conn, %{"data" => data = %{"type" => "product", "attributes" => _product_params}}) do
    changeset = Product.changeset(%Product{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, product} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", product_path(conn, :show, product))
        |> render("show.json-api", data: product)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    product = Repo.get!(Product, id)
    render(conn, "show.json-api", data: product)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "product", "attributes" => _product_params}}) do
    product = Repo.get!(Product, id)
    changeset = Product.changeset(product, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, product} ->
        render(conn, "show.json-api", data: product)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    product = Repo.get!(Product, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(product)

    send_resp(conn, :no_content, "")
  end

end
