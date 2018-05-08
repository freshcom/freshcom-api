defmodule BlueJet.Balance.Card do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Balance.Card.{Query, Proxy}
  alias BlueJet.Balance.IdentityService

  schema "cards" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string
    field :label, :string
    field :last_four_digit, :string
    field :exp_month, :integer
    field :exp_year, :integer
    field :fingerprint, :string
    field :cardholder_name, :string
    field :brand, :string
    field :country, :string
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

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :status,
    :account_id,
    :brand,
    :cardholder_name,
    :stripe_card_id,
    :stripe_customer_id,
    :fingerprint,
    :last_four_digit,
    :country,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def required_fields() do
    writable_fields() -- [:cardholder_name, :label]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
  end

  def changeset(card, :insert, params) do
    card
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> put_primary()
    |> validate()
  end

  def changeset(card, :update, params, locale \\ nil, default_locale \\ nil) do
    card = Proxy.put_account(card)
    default_locale = default_locale || card.account.default_locale
    locale = locale || default_locale

    card
    |> cast(params, writable_fields())
    |> Map.put(:action, :update)
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(card, :delete) do
    change(card)
    |> Map.put(:action, :delete)
  end

  def put_primary(changeset = %{ changes: %{ primary: true } }) do
    changeset
  end

  def put_primary(changeset = %{ changes: %{ primary: false } }) do
    delete_change(changeset, :primary)
  end

  def put_primary(changeset) do
    owner_id = get_field(changeset, :owner_id)
    owner_type = get_field(changeset, :owner_type)

    existing_primary_card = Repo.get_by(__MODULE__, owner_id: owner_id, owner_type: owner_type, status: "saved_by_owner", primary: true)

    if !existing_primary_card do
      put_change(changeset, :primary, true)
    else
      changeset
    end
  end

  defp create_or_update_card(%{ token_object: token_object, customer_id: stripe_customer_id }, fields = %{ status: status }, %{ account: account }) do
    existing_card = Repo.get_by(__MODULE__,
      account_id: account.id,
      owner_id: fields[:owner_id],
      owner_type: fields[:owner_type],
      fingerprint: token_object["card"]["fingerprint"]
    )

    case existing_card do
      nil ->
        change(%__MODULE__{}, %{
          account_id: account.id,
          account: account,
          status: status,
          source: token_object["id"],
          stripe_customer_id: stripe_customer_id,
          owner_id: fields[:owner_id],
          owner_type: fields[:owner_type],
        })
        |> put_primary()
        |> Repo.insert!()
        |> process()

      %{ status: ^status } ->
        {:ok, existing_card}

      existing_card ->
        card =
          existing_card
          |> change(%{ status: status, account: account })
          |> put_primary()
          |> Repo.update!()

        Proxy.update_stripe_card(card, %{ metadata: %{ fc_status: status, fc_account_id: account.id } })
        {:ok, card}
    end
  end

  @doc """
  Save the Stripe source as a card associated with the Stripe customer object,
  duplicate card will not be saved.

  If the given source is already a Stripe card ID then this function returns immediately
  with the given Stripe card ID.

  Returns `{:ok, source}` if successful where the `source` is a stripe card ID.
  """
  @spec keep_stripe_source(map, map, map) :: {:ok, String.t} | {:error, map}
  def keep_stripe_source(stripe_data = %{ source: source, customer_id: stripe_customer_id }, fields, opts) when not is_nil(stripe_customer_id) do
    case List.first(String.split(source, "_")) do
      "card" -> {:ok, source}
      "tok" -> keep_stripe_token_as_card(stripe_data, fields, opts)
    end
  end
  def keep_stripe_source(%{ source: source }, _, _), do: {:ok, source}

  @doc """
  Save the Stripe token as a card associated with the Stripe customer object,
  a token that contains the same card fingerprint of a existing card will not be
  created again, instead they will be updated according to `fields`.

  Returns `{:ok, stripe_card_id}` if successful.
  """
  @spec keep_stripe_token_as_card(map, map, map) :: {:ok, String.t} | {:error, map}
  def keep_stripe_token_as_card(%{ source: token, customer_id: stripe_customer_id }, fields, opts) when not is_nil(stripe_customer_id) do
    account = IdentityService.get_account(%{ account_id: opts[:account_id], account: opts[:account] })

    with {:ok, token_object} <- Proxy.retrieve_stripe_token(token, mode: account.mode),
         {:ok, card} <- create_or_update_card(%{ token_object: token_object, customer_id: stripe_customer_id }, fields, %{ account: account })
    do
      {:ok, card.stripe_card_id}
    else
      other -> other
    end
  end
  def keep_stripe_token_as_card(_, _, _), do: {:error, :stripe_customer_id_is_nil}

  @spec process(__MODULE__.t) :: {:ok, __MODULE__.t} | {:error, map}
  def process(card = %__MODULE__{ source: source }) when not is_nil(source) do
    card = Proxy.put_account(card)

    with {:ok, stripe_card} <- Proxy.create_stripe_card(card, %{ status: card.status, fc_card_id: card.id, owner_id: card.owner_id, owner_type: card.owner_type }) do
      changes = %{
        last_four_digit: stripe_card["last4"],
        exp_month: stripe_card["exp_month"],
        exp_year: stripe_card["exp_year"],
        fingerprint: stripe_card["fingerprint"],
        cardholder_name: stripe_card["name"],
        brand: stripe_card["brand"],
        country: stripe_card["country"],
        stripe_card_id: stripe_card["id"]
      }

      card =
        card
        |> change(changes)
        |> Repo.update!()

      {:ok, card}
    else
      other -> other
    end
  end

  @spec process(__MODULE__.t, Changeset.t) :: {:ok, __MODULE__.t} | {:error, map}
  def process(card, changeset = %{ action: :update }) do
    card = Proxy.put_account(card)

    if get_change(changeset, :exp_month) || get_change(changeset, :exp_year) do
      Proxy.update_stripe_card(card, %{ exp_month: card.exp_month, exp_year: card.exp_year })
    end

    {:ok, card}
  end

  def process(card = %{ primary: true }, %{ action: :delete }) do
    last_inserted_card =
      Query.default()
      |> Query.for_account(card.account_id)
      |> Query.with_owner(card.owner_type, card.owner_id)
      |> Query.not_primary()
      |> order_by(desc: :inserted_at)
      |> Repo.one()

    if last_inserted_card do
      Changeset.change(last_inserted_card, %{ primary: true })
      |> Repo.update!()
    end

    Proxy.delete_stripe_card(card)

    {:ok, card}
  end

  def process(card = %{ primary: false }, %{ action: :delete }) do
    card = Proxy.put_account(card)
    Proxy.delete_stripe_card(card)

    {:ok, card}
  end

  def process(card, _), do: {:ok, card}
end
