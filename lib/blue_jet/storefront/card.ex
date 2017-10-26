defmodule BlueJet.Storefront.Card do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.Customer
  alias BlueJet.Storefront.Card

  @type t :: Ecto.Schema.t

  schema "cards" do
    field :status, :string
    field :last_four_digit, :string
    field :exp_month, :integer
    field :exp_year, :integer
    field :fingerprint, :string
    field :cardholder_name, :string
    field :brand, :string
    field :stripe_card_id, :string
    field :source, :string, virtual: true

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :customer, Customer
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
    |> validate_assoc_account_scope(:customer)
  end

  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def process(card = %Card{ source: source }, customer) do
    with {:ok, stripe_card} <- create_stripe_card(card, customer, %{ status: card.status, fc_card_id: card.id }) do
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

  defp update_stripe_card(card = %Card{ stripe_card_id: stripe_card_id, customer_id: customer_id }, metadata) do
    customer = Repo.get!(Customer, customer_id)
    stripe_customer_id = customer.stripe_customer_id
    StripeClient.post("/customers/#{stripe_customer_id}/sources/#{stripe_card_id}", %{ metadata: metadata })
  end
  defp update_stripe_card(card = %Card{ stripe_card_id: stripe_card_id }, %Customer{ stripe_customer_id: stripe_customer_id }, metadata) do
    StripeClient.post("/customers/#{stripe_customer_id}/sources/#{stripe_card_id}", %{ metadata: metadata })
  end

  @spec create_stripe_card(Cart.t, Customer.t, map) :: {:ok, map} | {:error, map}
  defp create_stripe_card(%Card{ source: source }, %Customer{ stripe_customer_id: stripe_customer_id }, metadata) when not is_nil(stripe_customer_id) do
    StripeClient.post("/customers/#{stripe_customer_id}/sources", %{ source: source, metadata: metadata })
  end

  defp format_stripe_errors(stripe_errors) do
    [source: { stripe_errors["error"]["message"], [code: stripe_errors["error"]["code"], full_error_message: true] }]
  end
end
