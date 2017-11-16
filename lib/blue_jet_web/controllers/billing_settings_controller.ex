defmodule BlueJetWeb.BillingSettingsController do
  use BlueJetWeb, :controller

  alias BlueJet.Billing
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def show(conn = %{ assigns: assigns = %{ vas: vas } }, _) do
    request = %AccessRequest{
      vas: assigns[:vas],
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    {:ok, %AccessResponse{ data: billing_settings }} = Billing.get_billing_settings(request)

    render(conn, "show.json-api", data: billing_settings, opts: [include: conn.query_params["include"]])
  end

  def update(conn = %{ assigns: assigns = %{ vas: vas } }, %{ "data" => data = %{ "type" => "BillingSettings" } }) do
    request = %AccessRequest{
      vas: assigns[:vas],
      fields: Params.to_attributes(data),
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }

    case Billing.update_billing_settings(request) do
      {:ok, %AccessResponse{ data: billing_settings }} ->
        render(conn, "show.json-api", data: billing_settings, opts: [include: conn.query_params["include"]])
      {:error, %AccessResponse{ errors: errors }} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: extract_errors(errors))
    end
  end

  def delete(conn, %{"id" => id}) do
    account = Repo.get!(Account, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(account)

    send_resp(conn, :no_content, "")
  end

end
