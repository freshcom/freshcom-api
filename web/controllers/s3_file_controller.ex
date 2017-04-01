defmodule BlueJet.S3FileController do
  use BlueJet.Web, :controller

  alias BlueJet.S3File
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    s3_files = Repo.all(S3File)
    render(conn, "index.json-api", data: s3_files)
  end

  def create(conn, %{"data" => data = %{"type" => "S3File", "attributes" => _s3_file_params}}) do
    changeset = S3File.changeset(%S3File{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, s3_file} ->
        IO.inspect s3_file
        s3_file = S3File.put_presigned_url(s3_file)

        conn
        |> put_status(:created)
        |> put_resp_header("location", s3_file_path(conn, :show, s3_file))
        |> render("show.json-api", data: s3_file)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    s3_file = Repo.get!(S3File, id)
    render(conn, "show.json-api", data: s3_file)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "S3File", "attributes" => _s3_file_params}}) do
    s3_file = Repo.get!(S3File, id)
    changeset = S3File.changeset(s3_file, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, s3_file} ->
        s3_file = S3File.put_presigned_url(s3_file)

        render(conn, "show.json-api", data: s3_file)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    s3_file = Repo.get!(S3File, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(s3_file)

    send_resp(conn, :no_content, "")
  end

end
