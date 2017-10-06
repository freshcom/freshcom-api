defmodule BlueJet.Storefront.StripePaymentError do
  defexception [:message]

  def exception(value) do
    %BlueJet.Storefront.StripePaymentError{ message: "Stripe respond with the following error: #{Poison.encode!(value)}" }
  end
end