defmodule BlueJet.SkuController do
  use BlueJet.Web, :controller

  alias JaSerializer.Params
  alias BlueJet.Sku
  alias BlueJet.Translation

  plug :scrub_params, "data" when action in [:create, :update]

  def index(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, params) do
    query =
      Sku
      |> where([s], s.account_id == ^account_id)
      |> search([:name, :id], params["search"], conn.assigns[:locale])
    result_count = Repo.aggregate(query, :count, :id)
    total_count = Repo.aggregate(Sku, :count, :id)

    query = paginate(query, size: conn.assigns[:page_size], number: conn.assigns[:page_number])
    skus =
      Repo.all(query)
      |> Repo.preload(:external_file_collections)
      |> Translation.translate_collection(conn.assigns[:locale])
    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: skus, opts: [meta: meta, fields: conn.query_params["fields"]])
  end

  def create(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"data" => data = %{"type" => "Sku", "attributes" => _sku_params}}) do
    params = Map.merge(Params.to_attributes(data), %{ "account_id" => account_id })
    changeset = Sku.changeset(%Sku{}, params, conn.assigns[:locale])

    case Repo.insert(changeset) do
      {:ok, sku} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: sku)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(changeset))
    end
  end

  def show(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    sku =
      Sku
      |> Repo.get_by!(account_id: account_id, id: id)
      |> Repo.preload(:avatar)
      |> Repo.preload(:external_file_collections)
      |> Translation.translate(conn.assigns[:locale])

    render(conn, "show.json-api", data: sku, opts: [include: conn.query_params["include"]])
  end

  def update(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id, "data" => data = %{"type" => "Sku", "attributes" => _sku_params}}) do
    sku = Repo.get_by!(Sku, account_id: account_id, id: id)
    changeset = Sku.changeset(sku, Params.to_attributes(data), conn.assigns[:locale])

    case Repo.update(changeset) do
      {:ok, sku} ->
        sku = Translation.translate(sku, conn.assigns[:locale])
        render(conn, "show.json-api", data: sku)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(%{ assigns: %{ vas: %{ account_id: account_id, user_id: _ } } } = conn, %{"id" => id}) do
    sku = Repo.get_by!(Sku, account_id: account_id, id: id)
    Repo.delete!(sku)

    send_resp(conn, :no_content, "")
  end
end
