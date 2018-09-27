defmodule BlueJetWeb.DataImportController do
  use BlueJetWeb, :controller

  alias BlueJet.DataTrading

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def create(conn, %{"data" => %{"type" => "DataImport"}}),
    do: default(conn, :create, &DataTrading.create_data_import/1)
end
