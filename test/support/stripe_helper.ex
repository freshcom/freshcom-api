defmodule BlueJet.Stripe.TestHelper do
  alias BlueJet.Stripe.Client

  def stripe_token_fixture() do
    stripe_test_card = [
      "4242424242424242",
      "5555555555554444"
    ]
    {:ok, stripe_token} = Client.post("/tokens", %{card: %{
      number: Enum.random(stripe_test_card),
      exp_year: 2022,
      exp_month: 10,
      cvc: 123
    }}, mode: "test")

    stripe_token
  end

  def delete_stripe_customer(stripe_customer_id) do
    {:ok, _} = Client.delete("/customers/#{stripe_customer_id}", mode: "test")

    :ok
  end
end
