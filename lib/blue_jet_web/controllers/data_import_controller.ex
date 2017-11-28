defmodule BlueJetWeb.DataImportController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.DataTrading

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "DataImport" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads]
    }

    case DataTrading.create_data_import(request) do
      {:ok, %AccessResponse{ data: data_import }} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: data_import, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end
end
