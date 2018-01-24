defmodule BlueJet.Stripe.Client do
  alias BlueJet.Stripe.HttpClient

  def post(path, body, options \\ []) do
    key = stripe_secret_key(options)
    {:ok, response} = HttpClient.post(path, body, [{"Authorization", "Bearer #{key}"}])
    unwrap_response(response)
  end

  def delete(path, options \\ []) do
    key = stripe_secret_key(options)
    {:ok, response} = HttpClient.delete(path, [{"Authorization", "Bearer #{key}"}])
    unwrap_response(response)
  end

  def get(path, options \\ []) do
    key = stripe_secret_key(options)
    {:ok, response} = HttpClient.get(path, [{"Authorization", "Bearer #{key}"}])
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

  defp stripe_secret_key(options) do
    if options[:mode] == "test" do
      System.get_env("STRIPE_TEST_SECRET_KEY")
    else
      System.get_env("STRIPE_LIVE_SECRET_KEY")
    end
  end
end