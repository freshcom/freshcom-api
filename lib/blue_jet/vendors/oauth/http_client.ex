defmodule OauthHttpClient do
  use HTTPoison.Base

  defp process_request_headers(headers) do
    headers = headers ++ [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    headers
  end

  defp process_request_body(body = %{}) do
    body |> UriQuery.params |> URI.encode_query
  end
  defp process_request_body(body), do: body

  defp process_response_body(body) do
    body
    |> Poison.decode!
  end
end