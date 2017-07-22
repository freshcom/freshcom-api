defmodule BlueJet.CustomerController do
  use BlueJet.Web, :controller

  alias BlueJet.Customer
  alias JaSerializer.Params
  alias BlueJet.Storefront

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    customers = Repo.all(Customer)
    render(conn, "index.json-api", data: customers)
  end

  def create(conn = %{ assigns: assigns = %{ vas: %{ account_id: _ } } }, %{ "data" => data = %{ "type" => "Customer" } }) do
    preloads = assigns[:preloads] ++ [:refresh_token]
    request = %{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: preloads
    }


    case Storefront.create_customer(request) do
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

    customer = Storefront.get_customer!(request)

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

    case Storefront.update_customer(request) do
      {:ok, customer} ->
        render(conn, "show.json-api", data: customer, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
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
