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
    :account_id,
    :brand,
    :cardholder_name,
    :stripe_card_id,
    :fingerprint,
    :last_four_digit,
    :country,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    (__MODULE__.__schema__(:fields) -- @system_fields) ++ [:source]
  end

  def translatable_fields do
    [:custom_data]
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(card, :insert, params) do
    card
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate()
    |> put_primary()
    |> put_stripe_card_fields()
  end

  def changeset(card, :update, params, locale \\ nil) do
    card = Proxy.put_account(card)
    default_locale = card.account.default_locale
    locale = locale || default_locale

    card
    |> cast(params, castable_fields(:update))
    |> Map.put(:action, :update)
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(card, :delete) do
    change(card)
    |> Map.put(:action, :delete)
  end

  def castable_fields(:insert) do
    writable_fields()
  end

  def castable_fields(:update) do
    writable_fields() -- [:source, :stripe_customer_id]
  end

  defp put_primary(c = %{changes: %{primary: true}}), do: c
  defp put_primary(c = %{changes: %{primary: false}}), do: delete_change(c, :primary)

  defp put_primary(%{valid?: true} = changeset) do
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

  defp put_primary(changeset), do: changeset

  defp put_stripe_card_fields(%{valid?: true, changes: %{source: "card" <> _ = scard_id}} = changeset) do
    account = get_field(changeset, :account)
    scustomer_id = get_field(changeset, :stripe_customer_id)
    {:ok, stripe_card} = Proxy.retrieve_stripe_card(scard_id, scustomer_id, mode: account.mode)
    put_change_from_stripe_card(changeset, stripe_card)
  end

  defp put_stripe_card_fields(%{valid?: true, changes: %{source: "tok" <> _ = token}} = changeset) do
    account = get_field(changeset, :account)
    {:ok, %{"card" => stripe_card}} = Proxy.retrieve_stripe_token(token, mode: account.mode)
    put_change_from_stripe_card(changeset, stripe_card)
  end

  defp put_stripe_card_fields(changeset), do: changeset

  defp put_change_from_stripe_card(changeset, stripe_card) do
    changeset
    |> put_change(:stripe_card_id, stripe_card["id"])
    |> put_change(:last_four_digit, stripe_card["last4"])
    |> put_change(:exp_month, stripe_card["exp_month"])
    |> put_change(:exp_year, stripe_card["exp_year"])
    |> put_change(:fingerprint, stripe_card["fingerprint"])
    |> put_change(:cardholder_name, stripe_card["cardholder_name"])
    |> put_change(:brand, stripe_card["brand"])
    |> put_change(:country, stripe_card["country"])
  end

  def validate(changeset) do
    required_fields = required_fields(changeset.action)
    validate_required(changeset, required_fields)
  end

  defp required_fields(:insert) do
    [:source, :owner_id, :owner_type]
  end

  defp required_fields(:update) do
    []
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
end
