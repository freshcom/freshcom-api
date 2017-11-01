defmodule BlueJetWeb.AccountController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity.Account
  alias BlueJet.Identity
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    account = Repo.all(Account)
    render(conn, "index.json-api", data: account)
  end

  def create(conn, %{"data" => data = %{"type" => "account", "attributes" => _account_params}}) do
    changeset = Account.changeset(%Account{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, account} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", account_path(conn, :show, account))
        |> render("show.json-api", data: account)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: %{ account_id: account_id, user_id: _ } } }, _) do
    request = %{
      vas: assigns[:vas],
      account_id: account_id,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    account = Identity.get_account!(request)

    render(conn, "show.json-api", data: account, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: %{ account_id: account_id, user_id: _ } } }, %{"data" => data = %{"type" => "Account", "attributes" => _account_params}}) do
    request = %{
      vas: assigns[:vas],
      account_id: account_id,
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Identity.update_account(request) do
      {:ok, order} ->
        render(conn, "show.json-api", data: order, opts: [include: conn.query_params["include"]])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def delete(conn, %{"id" => id}) do
    account = Repo.get!(Account, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(account)

    send_resp(conn, :no_content, "")
  end

end
