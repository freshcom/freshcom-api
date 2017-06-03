defmodule BlueJet.UnlockableController do
  use BlueJet.Web, :controller

  alias BlueJet.Unlockable
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    unlockables = Repo.all(Unlockable)
    render(conn, "index.json-api", data: unlockables)
  end

  def create(conn, %{"data" => data = %{"type" => "unlockable", "attributes" => _unlockable_params}}) do
    changeset = Unlockable.changeset(%Unlockable{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, unlockable} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", unlockable_path(conn, :show, unlockable))
        |> render("show.json-api", data: unlockable)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    unlockable = Repo.get!(Unlockable, id)
    render(conn, "show.json-api", data: unlockable)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "unlockable", "attributes" => _unlockable_params}}) do
    unlockable = Repo.get!(Unlockable, id)
    changeset = Unlockable.changeset(unlockable, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, unlockable} ->
        render(conn, "show.json-api", data: unlockable)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    unlockable = Repo.get!(Unlockable, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(unlockable)

    send_resp(conn, :no_content, "")
  end

end
