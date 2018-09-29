defmodule BlueJet.Balance.Card.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Balance.{CRMService, StripeClient}
  alias BlueJet.Balance.Card
  alias BlueJet.CRM.Customer

  @spec get_owner(map) :: map | nil
  def get_owner(%{owner_type: "Customer"} = payment) do
    account = get_account(payment)
    identifiers = %{id: payment.owner_id}
    opts = %{account: account}

    owner = Map.get(payment, :owner) || CRMService.get_customer(identifiers, opts)

    if owner, do: Map.put(owner, :account, account), else: owner
  end

  def get_owner(_), do: nil

  @spec update_owner(struct, map) :: {:ok, map} | {:error, map}
  def update_owner(%Customer{} = customer, fields) do
    account = get_account(customer)
    CRMService.update_customer(customer, fields, %{account: account})
  end

  @spec create_stripe_customer(map) :: {:ok, map} | {:error, map}
  def create_stripe_customer(owner) do
    account = get_account(owner)
    owner_type =
      owner.__struct__
      |> Atom.to_string()
      |> String.split(".")
      |> Enum.at(-1)

    StripeClient.post(
      "/customers",
      %{
        email: owner.email,
        metadata: %{owner_id: owner.id, owner_type: owner_type, owner_name: owner.name}
      },
      mode: account.mode
    )
  end

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
