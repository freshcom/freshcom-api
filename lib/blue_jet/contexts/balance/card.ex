defmodule BlueJet.Balance.Card do
  use BlueJet, :data

  alias __MODULE__.{Query, Proxy}

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

  @type t :: Ecto.Schema.t()

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
    [:custom_data]
  end

  def required_fields() do
    writable_fields() -- [:cardholder_name, :label]
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
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

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
  end

  defp put_primary(c = %{changes: %{primary: true}}), do: c
  defp put_primary(c = %{changes: %{primary: false}}), do: delete_change(c, :primary)

  defp put_primary(changeset) do
    owner_id = get_field(changeset, :owner_id)
    owner_type = get_field(changeset, :owner_type)

    existing_primary_card =
      Repo.get_by(
        __MODULE__,
        owner_id: owner_id,
        owner_type: owner_type,
        status: "saved_by_owner",
        primary: true
      )

    if !existing_primary_card do
      put_change(changeset, :primary, true)
    else
      changeset
    end
  end

  @doc """
  Save the Stripe source as a card associated with the Stripe customer object,
  duplicate card will not be saved. The Stripe source can be either a Stripe card
  ID or Stripe token.

  If the given source is a Stripe card ID then this function returns immediately
  with the given Stripe card ID.

  If the given source is a Stripe token then this function will attempt to save
  the given token as a card. A token that contains the same card fingerprint of
  a existing card will not be created again, instead they will be udpated according
  to the given `fields`.

  Returns `{:ok, stripe_card_id}` if successful.
  """
  @spec keep_stripe_source(map, map, map) :: {:ok, String.t()} | {:error, map}
  def keep_stripe_source(
        %{source: source, customer_id: stripe_customer_id} = stripe_data,
        fields,
        opts
      )
      when not is_nil(stripe_customer_id) do
    prefix =
      source
      |> String.split("_")
      |> List.first()

    case prefix do
      "card" -> {:ok, source}
      "tok" -> keep_stripe_token_as_card(stripe_data, fields, opts)
    end
  end

  def keep_stripe_source(%{source: source}, _, _), do: {:ok, source}

  defp keep_stripe_token_as_card(
         %{source: token, customer_id: stripe_customer_id},
         fields,
         opts
       )
       when not is_nil(stripe_customer_id) do
    account = Proxy.get_account(%{account_id: opts[:account_id], account: opts[:account]})

    with {:ok, token_object} <- Proxy.retrieve_stripe_token(token, mode: account.mode),
         stripe_data <- %{token_object: token_object, customer_id: stripe_customer_id},
         {:ok, card} <- create_or_update_card(stripe_data, fields, %{account: account}) do
      {:ok, card.stripe_card_id}
    else
      other -> other
    end
  end

  defp keep_stripe_token_as_card(_, _, _), do: {:error, :stripe_customer_id_is_nil}

  defp create_or_update_card(
         %{token_object: token_object, customer_id: stripe_customer_id},
         fields,
         %{account: account}
       ) do
    existing_card =
      Repo.get_by(
        __MODULE__,
        account_id: account.id,
        owner_id: fields[:owner_id],
        owner_type: fields[:owner_type],
        fingerprint: token_object["card"]["fingerprint"]
      )

    card_fields =
      Map.merge(fields, %{
        account_id: account.id,
        account: account,
        stripe_customer_id: stripe_customer_id,
        source: token_object["id"]
      })

    create_or_update_card(existing_card, card_fields)
  end

  defp create_or_update_card(%{status: src_status} = existing_card, %{status: target_status})
       when src_status == target_status do
    {:ok, existing_card}
  end

  defp create_or_update_card(nil, fields) do
    create_card(fields)
  end

  defp create_or_update_card(%{} = existing_card, fields) do
    updated_card =
      existing_card
      |> change(Map.take(fields, [:status, :account]))
      |> put_primary()
      |> Repo.update!()

    Proxy.sync_to_stripe_card(updated_card)

    {:ok, updated_card}
  end

  defp create_card(fields) do
    card =
      %__MODULE__{}
      |> change(fields)
      |> put_primary()
      |> Repo.insert!()

    with {:ok, stripe_card} <- Proxy.sync_to_stripe_card(card) do
      sync_from_stripe_card(card, stripe_card)
    else
      other -> other
    end
  end

  @spec sync_from_stripe_card(__MODULE__.t(), map) :: {:ok, __MODULE__.t()} | {:error, map}
  def sync_from_stripe_card(card, stripe_card) do
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
  end

  @doc """
  Set a new primary card for the owner of the given card.

  If the given card is not a primary card then this function does nothing and
  immediately returns with `{:ok, given_card}`.

  If the given card is a primary card then this function will pick the most
  recent inserted card if any and mark it as the new primary card.

  Returns `{:ok, card}` if successful. If a new primary card is marked then
  `card` will be the new primary card, if nothing is changed then `card` will
  be the given card.
  """
  @spec set_new_primary(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, map}
  def set_new_primary(card = %{primary: true}) do
    filter = %{
      status: "saved_by_owner",
      owner_type: card.owner_type,
      owner_id: card.owner_id,
      primary: false
    }

    last_inserted_card =
      Query.default()
      |> for_account(card.account_id)
      |> Query.filter_by(filter)
      |> Query.except_id(card.id)
      |> sort_by(desc: :inserted_at)
      |> Repo.one()

    if last_inserted_card do
      Query.default()
      |> for_account(card.account_id)
      |> Query.filter_by(%{owner_type: card.owner_type, owner_id: card.owner_id})
      |> Repo.update_all(set: [primary: false])

      new_primary_card =
        last_inserted_card
        |> change(%{primary: true})
        |> Repo.update!()

      {:ok, new_primary_card}
    else
      {:ok, card}
    end
  end

  def set_new_primary(card = %{primary: false}), do: {:ok, card}
end
