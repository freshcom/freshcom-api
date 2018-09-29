defmodule BlueJet.Balance.Card do
  use BlueJet, :data

  alias __MODULE__.Proxy

  schema "cards" do
    field :account_id, UUID
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

    field :owner_id, UUID
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
    [:source, :owner_id, :owner_type, :status]
  end

  defp required_fields(:update) do
    [:status]
  end
end
