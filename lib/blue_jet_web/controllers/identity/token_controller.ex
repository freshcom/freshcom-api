defmodule BlueJetWeb.TokenController do
  use BlueJetWeb, :controller

  alias BlueJet.CreateRequest
  alias BlueJet.Identity

  def create(conn, params) do
    otp = Enum.at(get_req_header(conn, "x-freshcom-otp"), 0)
    params = Map.put(params, "otp", otp)

    with {:ok, %{data: token}} <- Identity.create_access_token(%CreateRequest{fields: params}) do
      conn
      |> put_status(:ok)
      |> json(token)
    else
      {:error, %{errors: errors}} ->
        conn = if errors.error == :invalid_otp do
          put_resp_header(conn, "X-Freshcom-OTP", "required; auth_method=tfa_sms")
        else
          conn
        end

        errors = if errors.error == :invalid_otp do
          %{ errors | error: :invalid_request, error_description: "OTP is invalid, please set OTP using the X-Freshcom-OTP header." }
        else
          errors
        end

        conn
        |> put_status(:bad_request)
        |> json(errors)
    end
  end
end
