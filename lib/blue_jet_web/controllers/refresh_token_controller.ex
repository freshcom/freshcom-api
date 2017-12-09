defmodule BlueJetWeb.RefreshTokenController do
  use BlueJetWeb, :controller

  alias BlueJet.Identity
  alias BlueJet.Identity.RefreshToken
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    jwts = Repo.all(RefreshToken)
    render(conn, "index.json-api", data: jwts)
  end

  def create(conn, params) do
    with {:ok, jwt} <- Identity.authenticate(params) do
      conn
      |> put_status(:created)
      |> render("show.json-api", data: jwt)
    else
      {:error, errors} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: errors)
    end
  end

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, _) do
    request = %AccessRequest{
      vas: assigns[:vas],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: refresh_token }} = Identity.get_refresh_token(request)

    render(conn, "show.json-api", data: refresh_token, opts: [include: conn.query_params["include"]])
  end
  def update(conn, %{"id" => id, "data" => data = %{"type" => "jwt", "attributes" => _jwt_params}}) do
    jwt = Repo.get!(RefreshToken, id)
    changeset = RefreshToken.changeset(jwt, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, jwt} ->
        render(conn, "show.json-api", data: jwt)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    jwt = Repo.get!(RefreshToken, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(jwt)

    send_resp(conn, :no_content, "")
  end

end
