defmodule BlueJet.ExternalFileCollectionController do
  use BlueJet.Web, :controller

  alias BlueJet.ExternalFileCollection
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, params) do
    query =
      ExternalFileCollection
      |> where([efc], efc.account_id == ^account_id)
      |> search([:name, :label, :id], params["search"], conn.assigns[:locale])
    result_count = Repo.aggregate(query, :count, :id)
    total_count = Repo.aggregate(query, :count, :id)

    query = paginate(query, size: conn.assigns[:page_size], number: conn.assigns[:page_number])
    external_file_collections = Repo.all(query) |> translate_collection(conn.assigns[:locale])
    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: external_file_collections, opts: [meta: meta])
  end

  def create(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"data" => data = %{"type" => "ExternalFileCollection", "attributes" => _external_file_collection_params}}) do
    params = Map.merge(Params.to_attributes(data), %{ "account_id" => account_id })
    changeset = ExternalFileCollection.changeset(%ExternalFileCollection{}, params)

    case Repo.insert(changeset) do
      {:ok, external_file_collection} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", external_file_collection_path(conn, :show, external_file_collection))
        |> render("show.json-api", data: external_file_collection)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    extrenal_file_collection =
      ExternalFileCollection
      |> Repo.get_by!(account_id: account_id, id: id)
      |> translate(conn.assigns[:locale])
      |> ExternalFileCollection.put_files

    render(conn, "show.json-api", data: extrenal_file_collection, opts: [include: conn.query_params["include"]])
  end

  def update(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id, "data" => data = %{"type" => "ExternalFileCollection", "attributes" => _external_file_collection_params}}) do
    external_file_collection = ExternalFileCollection |> Repo.get_by!(account_id: account_id, id: id)
    changeset = ExternalFileCollection.changeset(external_file_collection, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, external_file_collection} ->
        render(conn, "show.json-api", data: external_file_collection)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    external_file_collection = ExternalFileCollection |> Repo.get_by!(account_id: account_id, id: id)
    Repo.delete!(external_file_collection)

    send_resp(conn, :no_content, "")
  end

end
