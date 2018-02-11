defmodule BlueJet.Balance.Card.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.{IdentityService, StripeClient}
  alias BlueJet.Card

  def get_account(card) do
    card.account || IdentityService.get_account(card)
  end

  def put_account(card) do
    %{ card | account: get_account(card) }
  end

  def update_stripe_card(card = %{ stripe_card_id: stripe_card_id, stripe_customer_id: stripe_customer_id }, fields) do
    account = get_account(card)
    StripeClient.post("/customers/#{stripe_customer_id}/sources/#{stripe_card_id}", fields, mode: account.mode)
  end

  @spec create_stripe_card(Card.t, map) :: {:ok, map} | {:error, map}
  def create_stripe_card(card = %{ source: source, stripe_customer_id: stripe_customer_id }, metadata) when not is_nil(stripe_customer_id) do
    account = get_account(card)
    response = StripeClient.post("/customers/#{stripe_customer_id}/sources", %{ source: source, metadata: metadata }, mode: account.mode)

    case response do
      {:error, stripe_errors} ->
        response = %{ errors: [source: { stripe_errors["error"]["message"], [code: stripe_errors["error"]["code"], full_error_message: true] }] }
        {:error, response}

      other -> other
    end
  end

  @spec delete_stripe_card(Card.t) :: {:ok, map} | {:error, map}
  def delete_stripe_card(card = %{ stripe_card_id: stripe_card_id, stripe_customer_id: stripe_customer_id }) do
    account = get_account(card)
    StripeClient.delete("/customers/#{stripe_customer_id}/sources/#{stripe_card_id}", mode: account.mode)
  end

  @spec retrieve_stripe_token(String.t, Keyword.t) :: {:ok, map} | {:error, map}
  def retrieve_stripe_token(token, options) do
    StripeClient.get("/tokens/#{token}", options)
  end
end