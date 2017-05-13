defmodule BlueJet.JwtController do
  use BlueJet.Web, :controller

  alias BlueJet.Jwt
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    jwts = Repo.all(Jwt)
    render(conn, "index.json-api", data: jwts)
  end

  def create(conn, %{"data" => data = %{"type" => "Jwt", "attributes" => _jwt_params}}) do
    with {:ok, jwt} <- BlueJet.Authentication.get_jwt(Params.to_attributes(data)) do
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

  def show(conn, %{"id" => id}) do
    jwt = Repo.get!(Jwt, id)
    render(conn, "show.json-api", data: jwt)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "jwt", "attributes" => _jwt_params}}) do
    jwt = Repo.get!(Jwt, id)
    changeset = Jwt.changeset(jwt, Params.to_attributes(data))

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
    jwt = Repo.get!(Jwt, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(jwt)

    send_resp(conn, :no_content, "")
  end

end
