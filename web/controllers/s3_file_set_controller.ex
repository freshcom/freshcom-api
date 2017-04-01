defmodule BlueJet.S3FileSetController do
  use BlueJet.Web, :controller

  alias BlueJet.S3FileSet
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    s3_file_sets = Repo.all(S3FileSet)
    render(conn, "index.json-api", data: s3_file_sets)
  end

  def create(conn, %{"data" => data = %{"type" => "s3_file_set", "attributes" => _s3_file_set_params}}) do
    changeset = S3FileSet.changeset(%S3FileSet{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, s3_file_set} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", s3_file_set_path(conn, :show, s3_file_set))
        |> render("show.json-api", data: s3_file_set)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    s3_file_set = Repo.get!(S3FileSet, id)
    render(conn, "show.json-api", data: s3_file_set)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "s3_file_set", "attributes" => _s3_file_set_params}}) do
    s3_file_set = Repo.get!(S3FileSet, id)
    changeset = S3FileSet.changeset(s3_file_set, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, s3_file_set} ->
        render(conn, "show.json-api", data: s3_file_set)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    s3_file_set = Repo.get!(S3FileSet, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(s3_file_set)

    send_resp(conn, :no_content, "")
  end

end
