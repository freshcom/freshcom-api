defmodule StripeHttpClient do
  use HTTPoison.Base

  defp process_url(url) do
    "https://api.stripe.com/v1" <> url
  end

  defp process_request_headers(headers) do
    headers = headers ++ [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    headers
  end

  defp process_request_body(body = %{}) do
    body |> UriQuery.params(add_indices_to_lists: false) |> URI.encode_query
  end
  defp process_request_body(body), do: body

  defp process_response_body(body) do
    body
    |> Poison.decode!
  end
end