defmodule BlueJet.Balance.Refund.Proxy do
  use BlueJet, :proxy

  alias Decimal, as: D
  alias BlueJet.Repo
  alias BlueJet.Balance.StripeClient

  def create_stripe_refund(refund) do
    refund = Repo.preload(refund, :payment)
    stripe_charge_id = refund.payment.stripe_charge_id
    account = get_account(refund)

    StripeClient.post(
      "/refunds",
      %{
        charge: stripe_charge_id,
        amount: refund.amount_cents,
        metadata: %{refund_id: refund.id},
        expand: ["balance_transaction", "charge.balance_transaction"]
      },
      mode: account.mode
    )
  end

  def create_stripe_transfer_reversal(refund, stripe_refund) do
    refund = Repo.preload(refund, :payment)
    stripe_fee_cents = -stripe_refund["balance_transaction"]["fee"]

    freshcom_fee_rate =
      D.new(refund.payment.freshcom_fee_cents)
      |> D.div(D.new(refund.payment.amount_cents))

    freshcom_fee_cents =
      freshcom_fee_rate
      |> D.mult(D.new(refund.amount_cents))
      |> D.round()
      |> D.to_integer()

    transfer_reversal_amount_cents = refund.amount_cents - stripe_fee_cents - freshcom_fee_cents
    account = get_account(refund)

    StripeClient.post(
      "/transfers/#{refund.payment.stripe_transfer_id}/reversals",
      %{
        amount: transfer_reversal_amount_cents,
        metadata: %{refund_id: refund.id}
      },
      mode: account.mode
    )
  end
end
