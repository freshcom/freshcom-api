defmodule StripeClient do
  def post(path, body) do
    {:ok, response} = StripeHttpClient.post(path, body)
    unwrap_response(response)
  end

  def get(path) do
    {:ok, response} = StripeHttpClient.get(path)
    unwrap_response(response)
  end

  def unwrap_response(response = %{ status_code: 200 }) do
    {:ok, response.body}
  end
  def unwrap_response(response = %{ status_code: 201 }) do
    {:ok, response.body}
  end
  def unwrap_response(response) do
    {:error, response.body}
  end
end