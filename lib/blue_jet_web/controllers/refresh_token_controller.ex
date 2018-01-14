defmodule BlueJetWeb.RefreshTokenController do
  use BlueJetWeb, :controller

  alias JaSerializer.Params
  alias BlueJet.Identity

  plug :scrub_params, "data" when action in [:create, :update]

  def show(conn = %{ assigns: assigns }, _) do
    request = %AccessRequest{
      vas: assigns[:vas],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %{ data: refresh_token }} = Identity.get_refresh_token(request)

    render(conn, "show.json-api", data: refresh_token, opts: [include: conn.query_params["include"]])
  end
end
