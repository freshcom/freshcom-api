defmodule BlueJet.Balance.Card.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.StripeClient
  alias BlueJet.Balance.Card

  @spec sync_to_stripe_card(Card.t()) :: {:ok, map} | {:error, map}
  def sync_to_stripe_card(%{stripe_card_id: nil, source: s} = card) when not is_nil(s) do
    create_stripe_card(card, %{
      status: card.status,
      account_id: card.account_id,
      card_id: card.id,
      owner_id: card.owner_id,
      owner_type: card.owner_type
    })
  end

  def sync_to_stripe_card(card) do
    fields = %{
      exp_month: card.exp_month,
      exp_year: card.exp_year,
      metadata: %{status: card.status}
    }

    update_stripe_card(card, fields)
  end

  @spec update_stripe_card(Card.t(), map) :: {:ok, map} | {:error, map}
  def update_stripe_card(%{stripe_card_id: scard_id, stripe_customer_id: scustomer_id} = card, fields) do
    account = get_account(card)
    path = "/customers/#{scustomer_id}/sources/#{scard_id}"
    StripeClient.post(path, fields, mode: account.mode)
  end

  @spec create_stripe_card(Card.t(), map) :: {:ok, map} | {:error, map}
  def create_stripe_card(%{source: source, stripe_customer_id: scustomer_id} = card, metadata)
      when not is_nil(scustomer_id) do
    account = get_account(card)
    path = "/customers/#{scustomer_id}/sources"
    response = StripeClient.post(path, %{source: source, metadata: metadata}, mode: account.mode)

    case response do
      {:error, stripe_errors} ->
        message = stripe_errors["error"]["message"]
        code = stripe_errors["error"]["code"]

        {:error, %{errors: [source: {message, code: code}]}}

      other ->
        other
    end
  end

  @spec delete_stripe_card(Card.t()) :: {:ok, map} | {:error, map}
  def delete_stripe_card(%{stripe_card_id: scard_id, stripe_customer_id: scustomer_id} = card) do
    account = get_account(card)
    path = "/customers/#{scustomer_id}/sources/#{scard_id}"
    StripeClient.delete(path, mode: account.mode)
  end

  @spec retrieve_stripe_card(String.t(), String.t(), Keyword.t()) :: {:ok, map} | {:error, map}
  def retrieve_stripe_card(card_id, customer_id,  options) do
    StripeClient.get("/customers/#{customer_id}/sources/#{card_id}", options)
  end

  @spec retrieve_stripe_token(String.t(), Keyword.t()) :: {:ok, map} | {:error, map}
  def retrieve_stripe_token(token, options) do
    StripeClient.get("/tokens/#{token}", options)
  end
end
