defmodule BlueJetWeb.AccountMembershipshipController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity.AccountMembership
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    account_members = Repo.all(AccountMembership)
    render(conn, "index.json-api", data: account_members)
  end

  def create(conn, %{"data" => data = %{"type" => "account_member", "attributes" => _account_member_params}}) do
    changeset = AccountMembership.changeset(%AccountMembership{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, account_member} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: account_member)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    account_member = Repo.get!(AccountMembership, id)
    render(conn, "show.json-api", data: account_member)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "account_member", "attributes" => _account_member_params}}) do
    account_member = Repo.get!(AccountMembership, id)
    changeset = AccountMembership.changeset(account_member, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, account_member} ->
        render(conn, "show.json-api", data: account_member)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    account_member = Repo.get!(AccountMembership, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(account_member)

    send_resp(conn, :no_content, "")
  end

end
