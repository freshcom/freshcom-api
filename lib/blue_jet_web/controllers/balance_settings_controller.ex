defmodule BlueJetWeb.BalanceSettingsController do
  use BlueJetWeb, :controller

  alias BlueJet.Balance
  alias JaSerializer.Params

  action_fallback BlueJetWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  def show(conn = %{ assigns: assigns }, _) do
    request = %ContextRequest{
      vas: assigns[:vas],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %{ data: balance_settings }} = Balance.get_settings(request)

    render(conn, "show.json-api", data: balance_settings, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns }, %{ "data" => data = %{ "type" => "BalanceSettings" } }) do
    request = %ContextRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Balance.update_settings(request) do
      {:ok, %{ data: balance_settings }} ->
        render(conn, "show.json-api", data: balance_settings, opts: [include: conn.query_params["include"]])

      {:error, %{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))

      other -> other
    end
  end
end
