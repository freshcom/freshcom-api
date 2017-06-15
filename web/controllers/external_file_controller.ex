defmodule BlueJet.ExternalFileController do
  use BlueJet.Web, :controller

  alias JaSerializer.Params
  alias BlueJet.ExternalFile

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, params) do
    query =
      ExternalFile
      |> where([ef], ef.account_id == ^account_id)
      |> search([:name, :id], params["search"], conn.assigns[:locale])
    result_count = Repo.aggregate(query, :count, :id)
    total_count = Repo.aggregate(query, :count, :id)

    query = paginate(query, size: conn.assigns[:page_size], number: conn.assigns[:page_number])
    external_files = Repo.all(query)
                    |> Translation.translate_collection(conn.assigns[:locale])
    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    # TODO: underscore all query_params
    # IO.inspect conn.assigns[:fields]
    # fields = Macro.underscore(conn.query_params["fields"])
    render(conn, "index.json-api", data: external_files, opts: [meta: meta, fields: %{ "ExternalFile" => "name,content_type"}])
  end

  def create(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"data" => data = %{"type" => "ExternalFile", "attributes" => _external_file_params}}) do
    params = Map.merge(Params.to_attributes(data), %{ "account_id" => account_id })
    changeset = ExternalFile.changeset(%ExternalFile{}, params)

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

  def show(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    external_file = ExternalFile |> Repo.get_by!(account_id: account_id, id: id)
    render(conn, "show.json-api", data: external_file)
  end

  def update(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id, "data" => data = %{"type" => "ExternalFile", "attributes" => _external_file_params}}) do
    external_file = ExternalFile |> Repo.get_by!(account_id: account_id, id: id)
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

  def delete(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    external_file = ExternalFile |> Repo.get_by!(account_id: account_id, id: id)

    external_file
    |> ExternalFile.delete_object
    |> Repo.delete!

    send_resp(conn, :no_content, "")
  end
end
