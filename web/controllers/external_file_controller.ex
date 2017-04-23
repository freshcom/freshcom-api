defmodule BlueJet.ExternalFileController do
  use BlueJet.Web, :controller

  alias BlueJet.ExternalFile
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    external_files = Repo.all(ExternalFile)
    render(conn, "index.json-api", data: external_files)
  end

  def create(conn, %{"data" => data = %{"type" => "ExternalFile", "attributes" => _external_file_params}}) do
    changeset = ExternalFile.changeset(%ExternalFile{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, external_file} ->
        external_file = ExternalFile.put_url(external_file)

        conn
        |> put_status(:created)
        |> put_resp_header("location", external_file_path(conn, :show, external_file))
        |> render("show.json-api", data: external_file)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    external_file = Repo.get!(ExternalFile, id)
    render(conn, "show.json-api", data: external_file)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "ExternalFile", "attributes" => _external_file_params}}) do
    external_file = Repo.get!(ExternalFile, id)
    changeset = ExternalFile.changeset(external_file, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, external_file} ->
        external_file = ExternalFile.put_url(external_file)

        render(conn, "show.json-api", data: external_file)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    external_file = Repo.get!(ExternalFile, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(external_file)

    send_resp(conn, :no_content, "")
  end

end
