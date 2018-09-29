defmodule BlueJet.Balance.Payment.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.Payment
  alias BlueJet.Balance.StripeClient

  @spec create_stripe_charge(Payment.t(), String.t(), Settings.t()) :: {:ok, map} | {:error, map}
  def create_stripe_charge(
        %{capture: capture, stripe_customer_id: stripe_customer_id} = payment,
        source,
        destination_stripe_user_id
      ) do
    stripe_request = %{
      amount: payment.amount_cents,
      source: source,
      capture: capture,
      currency: "CAD",
      destination: %{
        account: destination_stripe_user_id,
        amount: payment.destination_amount_cents
      },
      metadata: %{
        payment_id: payment.id,
        account_id: payment.account_id
      },
      expand: ["transfer", "balance_transaction"]
    }

    stripe_request =
      if stripe_customer_id do
        Map.put(stripe_request, :customer, stripe_customer_id)
      else
        stripe_request
      end

    account = get_account(payment)
    StripeClient.post("/charges", stripe_request, mode: account.mode)
  end

  @spec capture_stripe_charge(Payment.t()) :: {:ok, map} | {:error, map}
  def capture_stripe_charge(payment) do
    account = get_account(payment)

    StripeClient.post(
      "/charges/#{payment.stripe_charge_id}/capture",
      %{amount: payment.capture_amount_cents},
      mode: account.mode
    )
  end

  def put(payment, _, _), do: payment
end
