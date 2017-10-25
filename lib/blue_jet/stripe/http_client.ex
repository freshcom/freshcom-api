defmodule StripeHttpClient do
  use HTTPoison.Base

  defp process_url(url) do
    "https://api.stripe.com/v1" <> url
  end

  defp process_request_headers(headers) do
    key = System.get_env("STRIPE_SECRET_KEY")

    headers = headers ++ [
      {"Authorization", "Bearer #{key}"},
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