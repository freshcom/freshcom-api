defmodule BlueJet.Billing.Card do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Billing.Card

  @type t :: Ecto.Schema.t

  schema "cards" do
    field :account_id, Ecto.UUID
    field :status, :string
    field :last_four_digit, :string
    field :exp_month, :integer
    field :exp_year, :integer
    field :fingerprint, :string
    field :cardholder_name, :string
    field :brand, :string
    field :stripe_card_id, :string
    field :stripe_customer_id, :string
    field :primary, :boolean, default: false
    field :source, :string, virtual: true

    field :owner_id, Ecto.UUID
    field :owner_type, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Card.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Card.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def required_fields() do
    writable_fields() -- [:cardholder_name]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> foreign_key_constraint(:account_id)
  end

  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_primary()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def query() do
    from(c in Card, order_by: [desc: c.inserted_at, desc: c.updated_at])
  end

  def put_primary(changeset) do
    owner_id = get_field(changeset, :owner_id)
    owner_type = get_field(changeset, :owner_type)

    existing_primary_card = Repo.get_by(Card, owner_id: owner_id, owner_type: owner_type, status: "saved_by_customer", primary: true)

    if !existing_primary_card do
      put_change(changeset, :primary, true)
    else
      changeset
    end
  end

  @doc """
  Save the Stripe source as a card associated with the Stripe customer object,
  duplicate card will not be saved.

  If the given source is already a Stripe card ID then this function returns immediately
  with the given Stripe card ID.

  Returns `{:ok, source}` if successful where the `source` is a stripe card ID.
  """
  @spec keep_stripe_source(Map.t, Map.t) :: {:ok, String.t} | {:error, map}
  def keep_stripe_source(stripe_data = %{ source: source, customer_id: stripe_customer_id }, fields) when not is_nil(stripe_customer_id) do
    case List.first(String.split(source, "_")) do
      "card" -> {:ok, source}
      "tok" -> keep_stripe_token_as_card(stripe_data, fields)
    end
  end
  def keep_stripe_source(%{ source: source }, _), do: {:ok, source}

  @doc """
  Save the Stripe token as a card associated with the Stripe customer object,
  a token that contains the same card fingerprint of a existing card will not be
  created again, instead they will be updated according to `opts`.

  Returns `{:ok, stripe_card_id}` if successful.
  """
  @spec keep_stripe_token_as_card(Map.t, Map.t) :: {:ok, String.t} | {:error, map}
  def keep_stripe_token_as_card(%{ source: token, customer_id: stripe_customer_id }, fields = %{ status: status }) when not is_nil(stripe_customer_id) do
    Repo.transaction(fn ->
      with {:ok, token_object} <- retrieve_stripe_token(token),
           nil <- Repo.get_by(Card, owner_id: fields[:owner_id], owner_type: fields[:owner_type], fingerprint: token_object["card"]["fingerprint"]),
           # Create the new card
           card <- Repo.insert!(%Card{ status: status, source: token, stripe_customer_id: stripe_customer_id, account_id: fields[:account_id], owner_id: fields[:owner_id], owner_type: fields[:owner_type] }),
           {:ok, card} <- Card.process(card)
      do
        card.stripe_card_id
      else
        # If there is existing card with the same status just return
        %Card{ stripe_card_id: stripe_card_id, status: ^status } -> {:ok, stripe_card_id}

        # If there is existing card with different status then we update the card
        card = %Card{ stripe_card_id: stripe_card_id } ->
          card
          |> Card.changeset(%{ status: status })
          |> Repo.update!()
          |> Card.update_stripe_card(%{ fc_status: status, fc_account_id: card.account_id })
          stripe_card_id

        {:error, errors} -> Repo.rollback(errors)
        other -> Repo.rollback(other)
      end
    end)
  end
  def keep_stripe_token_as_card(_, _, _), do: {:error, :stripe_customer_id_is_nil}

  @spec process(Card.t, Map.t) :: {:ok, Card.t} | {:error, map}
  def process(card = %Card{ source: source }) do
    with {:ok, stripe_card} <- create_stripe_card(card, %{ status: card.status, fc_card_id: card.id, owner_id: card.owner_id, owner_type: card.owner_type }) do
      changes = %{
        last_four_digit: stripe_card["last4"],
        exp_month: stripe_card["exp_month"],
        exp_year: stripe_card["exp_year"],
        fingerprint: stripe_card["fingerprint"],
        cardholder_name: stripe_card["name"],
        brand: stripe_card["brand"],
        stripe_card_id: stripe_card["id"]
      }

      card =
        card
        |> Card.changeset(changes)
        |> Repo.update!()

      {:ok, card}
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end
  def process(card, _), do: {:ok, card}

  defp update_stripe_card(card = %Card{ stripe_card_id: stripe_card_id, stripe_customer_id: stripe_customer_id }, metadata) do
    StripeClient.post("/customers/#{stripe_customer_id}/sources/#{stripe_card_id}", %{ metadata: metadata })
  end

  @spec create_stripe_card(Cart.t, Map.t) :: {:ok, map} | {:error, map}
  defp create_stripe_card(%Card{ source: source, stripe_customer_id: stripe_customer_id }, metadata) when not is_nil(stripe_customer_id) do
    StripeClient.post("/customers/#{stripe_customer_id}/sources", %{ source: source, metadata: metadata })
  end

  @spec retrieve_stripe_token(String.t) :: {:ok, map} | {:error, map}
  defp retrieve_stripe_token(token) do
    StripeClient.get("/tokens/#{token}")
  end

  defp format_stripe_errors(stripe_errors) do
    [source: { stripe_errors["error"]["message"], [code: stripe_errors["error"]["code"], full_error_message: true] }]
  end
end
