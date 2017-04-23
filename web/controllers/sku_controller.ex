defmodule BlueJet.SkuController do
  use BlueJet.Web, :controller

  alias BlueJet.Sku
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, params) do
    query = Sku |> search(:name, params["search"], conn.assigns[:locale])
    result_count = Repo.aggregate(query, :count, :id)
    total_count = Repo.aggregate(Sku, :count, :id)

    query = paginate(query, size: conn.assigns[:page_size], number: conn.assigns[:page_number])
    skus = Repo.all(query)
          |> Repo.preload(:s3_file_sets)
          |> translate_collection(conn.assigns[:locale])
    meta = %{
      totalCount: total_count,
      resultCount: result_count
    }

    render(conn, "index.json-api", data: skus, opts: [meta: meta, fields: conn.query_params["fields"]])
  end

  def create(conn, %{"data" => data = %{"type" => "Sku", "attributes" => _sku_params}}) do
    changeset = Sku.changeset(%Sku{}, conn.assigns[:locale], Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, sku} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", sku_path(conn, :show, sku))
        |> render("show.json-api", data: sku)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    sku = Sku
          |> Repo.get!(id)
          |> Repo.preload(:avatar)
          |> Repo.preload(:s3_file_sets)
          |> translate(conn.assigns[:locale])

    render(conn, "show.json-api", data: sku, opts: [include: conn.query_params["include"]])
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "Sku", "attributes" => _sku_params}}) do
    sku = Repo.get!(Sku, id)
    changeset = Sku.changeset(sku, conn.assigns[:locale], Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, sku} ->
        sku = translate(sku, conn.assigns[:locale])
        render(conn, "show.json-api", data: sku)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    sku = Repo.get!(Sku, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(sku)

    send_resp(conn, :no_content, "")
  end

  defp translate_collection(collection, locale) when locale !== "en" do
    Enum.map(collection, fn(item) -> translate(item, locale) end)
  end
  defp translate_collection(collection, _locale), do: collection

  defp translate(struct, locale) when locale !== "en" do
    t_attributes = Map.new(Map.get(struct.translations, locale, %{}), fn({k, v}) -> { String.to_atom(k), v } end)
    Map.merge(struct, t_attributes)
  end
  defp translate(struct, _locale), do: struct

end
