defmodule BlueJet.AccountController do
  use BlueJet.Web, :controller

  alias BlueJet.Account
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

  def show(conn, %{"id" => id}) do
    account = Repo.get!(Account, id)
    render(conn, "show.json-api", data: account)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "account", "attributes" => _account_params}}) do
    account = Repo.get!(Account, id)
    changeset = Account.changeset(account, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, account} ->
        render(conn, "show.json-api", data: account)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
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
