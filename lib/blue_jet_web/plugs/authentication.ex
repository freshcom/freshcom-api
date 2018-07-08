defmodule BlueJet.Plugs.Authentication do
  require Logger
  import Plug.Conn

  def init(exception_paths), do: exception_paths

  def call(conn, exception_paths \\ []) do
    with [auth] <- get_req_header(conn, "authorization"),
         ["Bearer", access_token] <- String.split(auth),
         {:ok, verified_authorization_payload} <- verify_access_token(access_token),
         {:ok, verified_authorization_scope} <- extract_authorization_scope(verified_authorization_payload)
    do
      Logger.info("Verified Authorization Scope: #{inspect verified_authorization_scope}")
      assign(conn, :vas, verified_authorization_scope)
    else
      true -> conn
      _ ->
        if Enum.member?(exception_paths, conn.request_path) do
          assign(conn, :vas, %{})
        else
          halt send_resp(conn, 401, "")
        end
    end
  end

  def verify_access_token(access_token) do
    with {true, %{ "prn" => _, "exp" => exp } = fields} <- BlueJet.Identity.Jwt.verify_token(access_token),
         true <- exp >= System.system_time(:second)
    do
      {:ok, fields}
    else
      {false, _} -> {:error, :invalid}
      false -> {:error, :invalid}
    end
  end

  def extract_authorization_scope(%{ "prn" => user_id, "aud" => account_id, "typ" => "user" }) do
    {:ok, %{ user_id: user_id, account_id: account_id }}
  end
  def extract_authorization_scope(%{ "prn" => account_id, "typ" => "publishable" }) do
    {:ok, %{ user_id: nil, account_id: account_id }}
  end
end
