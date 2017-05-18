defmodule BlueJet.CustomerController do
  use BlueJet.Web, :controller

  alias BlueJet.Customer
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    customers = Repo.all(Customer)
    render(conn, "index.json-api", data: customers)
  end

  def create(conn, %{"data" => data = %{"type" => "customer", "attributes" => _customer_params}}) do
    changeset = Customer.changeset(%Customer{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, customer} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", customer_path(conn, :show, customer))
        |> render("show.json-api", data: customer)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    customer = Repo.get!(Customer, id)
    render(conn, "show.json-api", data: customer)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "customer", "attributes" => _customer_params}}) do
    customer = Repo.get!(Customer, id)
    changeset = Customer.changeset(customer, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, customer} ->
        render(conn, "show.json-api", data: customer)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    customer = Repo.get!(Customer, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(customer)

    send_resp(conn, :no_content, "")
  end

end
