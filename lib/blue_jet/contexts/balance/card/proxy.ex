defmodule BlueJet.Balance.Card.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.StripeClient
  alias BlueJet.Balance.Card

  @spec sync_to_stripe_card(Card.t) :: {:ok, map} | {:error, map}
  def sync_to_stripe_card(card = %{ stripe_card_id: nil, source: source }) when not is_nil(source) do
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
      metadata: %{
        status: card.status
      }
    }

    update_stripe_card(card, fields)
  end

  @spec update_stripe_card(Card.t, map) :: {:ok, map} | {:error, map}
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
        response = %{ errors: [source: {stripe_errors["error"]["message"], code: stripe_errors["error"]["code"]}] }
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